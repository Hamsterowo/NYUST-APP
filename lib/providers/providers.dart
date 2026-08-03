// Riverpod 3.x：ChangeNotifierProvider / StateProvider 已移到 legacy。
import 'dart:ui' show Locale;
import 'package:flutter/widgets.dart'
    show WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/per_app_locale.dart';
import 'data_provider.dart';
import '../services/calendar_reminder_service.dart';
import '../services/connectivity_service.dart';
import '../services/server_time_service.dart';
import '../services/grade_notification_service.dart';
import '../utils/calendar_reminder_planner.dart';

/// Stage 5：DI 由 `provider` 套件全面改吃 Riverpod。
///
/// AuthProvider / DataProvider 內部仍是 ChangeNotifier（登入狀態機不動），
/// 透過 Riverpod 的 ChangeNotifierProvider 暴露；未來可再細拆成 Notifier。

/// 全域唯一的 AuthProvider。
final authProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});

/// 全域唯一的 DataProvider，架在 AuthProvider 之上。
///
/// 用 `ref.read`（而非 watch）取得 AuthProvider 實例：兩者都是單例、
/// 生命週期與 App 同壽，DataProvider 只需建立一次，不該因 auth 通知而重建。
final dataProvider = ChangeNotifierProvider<DataProvider>((ref) {
  final auth = ref.read(authProvider);
  return DataProvider(auth.api, auth);
});

/// 底部分頁索引（取代 NavigationProvider）。
final navIndexProvider = StateProvider<int>((ref) => 0);

/// 行事曆分頁在 [navIndexProvider] 裡的索引。
///
/// 具名而不是散在各處寫 `3`：分頁順序改一次就得全部跟著改，而漏掉的那一處
/// 會安靜地跳到別的分頁。
const int navIndexCalendar = 3;

/// 要行事曆頁跳到並選中的日期；`null` = 沒有待處理的請求。
///
/// 由點擊通知觸發（見 [NotificationNavigator]）。行事曆頁把日期套用完之後會
/// 把它清回 `null`，所以同一個日期再送一次仍然有效。
final calendarFocusDateProvider = StateProvider<DateTime?>((ref) => null);

/// App 內語言設定。[locale] 為 `null` 表示跟隨系統。
///
/// [isResolved] 在儲存的設定讀進來之前是 false —— 此時 [locale] 只是「還沒讀到
/// 設定，先跟隨系統」的**暫定值**。開機後畫面上的語系可能因此一次性改變，那不是
/// 使用者在切換語言；會依語言重抓資料的畫面必須等 [isResolved] 才開始計較語系，
/// 否則每次開機都會多打一輪重抓、並把已顯示的內容打回骨架。
typedef LocaleSetting = ({Locale? locale, bool isResolved});

/// App 內語言覆寫。兩個 MaterialApp 都吃這個值（取 [LocaleSetting.locale]）。
final localeProvider = NotifierProvider<LocaleNotifier, LocaleSetting>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<LocaleSetting>
    with WidgetsBindingObserver {
  static const _prefKey = 'app_locale';

  /// Android 13+：語言覆寫交由系統的 per-app locale 儲存（與系統設定頁
  /// 雙向同步）；此時 [state] 只是系統值的鏡像，供選單顯示目前選項。
  bool _systemBacked = false;

  @override
  LocaleSetting build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    _load();
    return (locale: null, isResolved: false); // 讀到設定前先跟隨系統。
  }

  /// 系統語系變更（含使用者從系統設定頁改 per-app 語言）時刷新鏡像，
  /// 讓設定頁的「目前語言」顯示保持同步。
  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_systemBacked) _refreshFromSystem();
  }

  /// 套用語言覆寫並標記設定已讀完。同步更新 `Intl.defaultLocale`，
  /// 讓以它判斷語系的邏輯（LanguageInterceptor、CalendarScraper 等）跟著走。
  void _apply(Locale? locale) {
    state = (locale: locale, isResolved: true);
    Intl.defaultLocale = locale?.languageCode;
  }

  Future<void> _refreshFromSystem() async {
    _apply(await PerAppLocale.current());
  }

  Future<void> _load() async {
    _systemBacked = await PerAppLocale.isSupported();
    if (_systemBacked) {
      // 一次性遷移：把舊版存在 SharedPreferences 的 App 內覆寫推入系統
      // per-app 設定後清除，之後以系統為唯一事實來源。
      try {
        final prefs = await SharedPreferences.getInstance();
        final code = prefs.getString(_prefKey);
        if (code != null && code.isNotEmpty) {
          await PerAppLocale.set(Locale(code));
          await prefs.remove(_prefKey);
        }
      } catch (_) {}
      await _refreshFromSystem();
      return;
    }
    Locale? saved;
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey);
      if (code != null && code.isNotEmpty) saved = Locale(code);
    } catch (_) {}
    // 沒有存過設定也要送出 isResolved：等著它的畫面才不會一直等不到。
    _apply(saved);
  }

  /// 設定語言覆寫；`null` 表示清除覆寫、跟隨系統。
  ///
  /// Android 13+ 寫入系統 per-app 設定（系統設定頁會同步顯示），
  /// 其他平台持久化到 SharedPreferences。
  Future<void> setLocale(Locale? locale) async {
    _apply(locale);
    if (_systemBacked) {
      await PerAppLocale.set(locale);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_prefKey);
      } else {
        await prefs.setString(_prefKey, locale.languageCode);
      }
    } catch (_) {}
  }
}

/// 成績通知（背景檢查）是否啟用。設定分頁與成績頁的就地開關面板共用此狀態，
/// 任一處切換後另一處會即時同步（不需重開 App）。
final gradeNotificationEnabledProvider =
    NotifierProvider<GradeNotificationEnabledNotifier, bool>(
      GradeNotificationEnabledNotifier.new,
    );

class GradeNotificationEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false; // 載入前預設關閉；讀到偏好設定後再更新。
  }

  Future<void> _load() async {
    state = await GradeNotificationService.isEnabled();
  }

  /// 切換啟用狀態；回傳結果供 UI 顯示提示（例如權限被拒）。
  Future<GradeNotificationResult> setEnabled(bool value) async {
    final result = await GradeNotificationService.setEnabled(value);
    state = result == GradeNotificationResult.permissionDenied ? false : value;
    return result;
  }
}

/// 目前已訂閱的行事曆提醒分類。預設全部關閉。
///
/// 設定頁與（之後的）行事曆頁鈴鐺共用此狀態，從任一入口變更後另一入口看到的
/// 都是同一份。
final calendarReminderCategoriesProvider =
    NotifierProvider<CalendarReminderCategoriesNotifier, Set<ReminderCategory>>(
      CalendarReminderCategoriesNotifier.new,
    );

class CalendarReminderCategoriesNotifier
    extends Notifier<Set<ReminderCategory>> {
  @override
  Set<ReminderCategory> build() {
    _load();
    return const {}; // 讀到偏好設定前先當作全部關閉。
  }

  Future<void> _load() async {
    state = await CalendarReminderService.loadCategories();
  }

  /// 開啟／關閉一個分類並立即重排；回傳結果供 UI 顯示提示（例如權限被拒）。
  Future<CalendarReminderResult> setEnabled(
    ReminderCategory category,
    bool enabled,
    AppLocalizations l10n,
  ) async {
    final result = await CalendarReminderService.setCategoryEnabled(
      category,
      enabled,
      l10n,
    );
    if (result == CalendarReminderResult.applied) {
      state = await CalendarReminderService.loadCategories();
    }
    return result;
  }
}

/// 行事曆提醒的提醒清單（提前 N 天 + 時刻）。四個分類共用同一組。
final calendarReminderRulesProvider =
    NotifierProvider<CalendarReminderRulesNotifier, List<ReminderRule>>(
      CalendarReminderRulesNotifier.new,
    );

class CalendarReminderRulesNotifier extends Notifier<List<ReminderRule>> {
  @override
  List<ReminderRule> build() {
    _load();
    // 讀到偏好設定前先顯示預設值 —— 絕大多數使用者的實際設定就是它，
    // 從空清單開始反而會讓每次進頁面都閃一下「尚未設定任何提醒」。
    return const [ReminderRule.defaultRule];
  }

  Future<void> _load() async {
    state = await CalendarReminderService.loadRules();
  }

  /// 換掉整份清單並立即重排。
  Future<void> setRules(List<ReminderRule> rules, AppLocalizations l10n) async {
    await CalendarReminderService.setRules(rules, l10n);
    state = await CalendarReminderService.loadRules();
  }
}

/// 目前是否在線上（`true` = 有網路介面）。用於離線橫幅等 UX。
///
/// 初值先給 `true`，避免 App 一啟動、串流尚未回報前就閃現離線橫幅。
final isOnlineProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.instance.onStatusChange;
});

/// 裝置時間是否與伺服器時間偏差過大（`true` = 誤差過大）。用於時間誤差橫幅。
///
/// 訂閱當下先種入目前值，再跟隨後續變化 —— 因為偏差可能在 HomeScreen 建立
/// （訂閱）之前、於登入的 prefetch 階段就已偵測到，而 broadcast stream 不會
/// 補發給晚到的訂閱者。尚未收到任何伺服器回應前為 `false`。
final isClockSkewedProvider = StreamProvider<bool>((ref) async* {
  yield ServerTimeService.instance.isSkewed;
  yield* ServerTimeService.instance.onSkewChange;
});
