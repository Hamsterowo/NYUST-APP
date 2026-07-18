// Riverpod 3.x：ChangeNotifierProvider / StateProvider 已移到 legacy。
import 'dart:ui' show Locale;
import 'package:flutter/widgets.dart'
    show WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';
import '../services/per_app_locale.dart';
import 'data_provider.dart';
import '../services/connectivity_service.dart';
import '../services/server_time_service.dart';
import '../services/grade_notification_service.dart';

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

/// App 內語言覆寫（`null` = 跟隨系統）。兩個 MaterialApp 都吃這個值。
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale?> with WidgetsBindingObserver {
  static const _prefKey = 'app_locale';

  /// Android 13+：語言覆寫交由系統的 per-app locale 儲存（與系統設定頁
  /// 雙向同步）；此時 [state] 只是系統值的鏡像，供選單顯示目前選項。
  bool _systemBacked = false;

  @override
  Locale? build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    _load();
    return null; // 讀到設定前先跟隨系統。
  }

  /// 系統語系變更（含使用者從系統設定頁改 per-app 語言）時刷新鏡像，
  /// 讓設定頁的「目前語言」顯示保持同步。
  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_systemBacked) _refreshFromSystem();
  }

  Future<void> _refreshFromSystem() async {
    final current = await PerAppLocale.current();
    state = current;
    Intl.defaultLocale = current?.languageCode;
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey);
      if (code != null && code.isNotEmpty) {
        state = Locale(code);
        Intl.defaultLocale = code;
      }
    } catch (_) {}
  }

  /// 設定語言覆寫；`null` 表示清除覆寫、跟隨系統。
  ///
  /// Android 13+ 寫入系統 per-app 設定（系統設定頁會同步顯示），
  /// 其他平台持久化到 SharedPreferences。同步更新 `Intl.defaultLocale`，
  /// 讓以它判斷語系的邏輯（LanguageInterceptor、CalendarScraper 等）跟著走。
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    Intl.defaultLocale = locale?.languageCode;
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
