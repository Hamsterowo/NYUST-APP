import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../firebase_options.dart';

/// 是否啟用 Firebase。由 compile-time flag 控制，debug 預設關閉。
///
/// 開啟方式：`flutter run/build ... --dart-define=USE_FIREBASE=true`
const bool useFirebase = bool.fromEnvironment(
  'USE_FIREBASE',
  defaultValue: false,
);

/// 集中管理 Firebase Analytics / Crashlytics 的初始化與存取。
///
/// 所有存取都是 null-aware：未啟用（[useFirebase] 為 false）、或在尚未設定
/// Firebase 的平台（目前僅 Android 有設定）時，[analytics] / [crashlytics]
/// 皆回傳 null，呼叫端用 `?.` 即可安全略過。
class FirebaseService {
  bool _initialized = false;

  /// Firebase 是否真的可用（已啟用且初始化成功）。
  bool get isEnabled => useFirebase && _initialized;

  /// 目前只有 Android 設定了 Firebase（見 firebase_options.dart）。
  /// 未來以 `flutterfire configure` 加入 iOS/web 後可放寬此判斷。
  bool get _isConfiguredPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 在 App 啟動早期呼叫。未啟用或非設定平台時為 no-op。
  Future<void> init() async {
    if (!useFirebase || !_isConfiguredPlatform) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Manifest 已將資料收集預設關閉（連 flag-off 建置的原生自動初始化也不收集）；
      // 這裡在 flag-on 時才程式化開啟。App 層級總開關會一併恢復 firebase-sessions
      // 等吃「資料收集預設值」的支援函式庫，per-product 開關則精準控制 Analytics/Crashlytics。
      await Firebase.app().setAutomaticDataCollectionEnabled(true);
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // 將 Flutter 框架錯誤與未捕捉的非同步錯誤導向 Crashlytics。
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      _initialized = true;
      if (kDebugMode) {
        print('FirebaseService: initialized, data collection enabled');
      }
    } catch (e) {
      if (kDebugMode) print('FirebaseService: init failed: $e');
    }
  }

  FirebaseAnalytics? get analytics =>
      isEnabled ? FirebaseAnalytics.instance : null;

  FirebaseCrashlytics? get crashlytics =>
      isEnabled ? FirebaseCrashlytics.instance : null;

  /// 記錄一個 Analytics 事件（未啟用時安全略過）。
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await analytics?.logEvent(name: name, parameters: parameters);
  }
}

/// 全 App 共用的單例。
final firebaseService = FirebaseService();
