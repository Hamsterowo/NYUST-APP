import 'dart:async';

import 'package:flutter/widgets.dart';

import '../utils/clock_drift.dart';

/// 全 App 共用的「可信任時間」服務。
///
/// 從每個 HTTP 回應都自帶的 `Date` header 取得伺服器 UTC 時間，並以**單調時鐘**
/// （[Stopwatch]，不受使用者改動裝置牆上時鐘影響）當錨點推算「真實時間」，
/// 對外提供：
/// - [now]：校正後的現在時間，**固定以台灣時區 (UTC+8) 的牆上時間呈現**，不受
///   裝置時區設定影響（裝置時區設錯時仍顯示正確的台灣日期/時間）。供課表紅線、
///   行事曆「今天」等顯示用途。
/// - [trueUtcNow]：校正後的 UTC instant，供 nonce 等需要正確時間戳的用途。
/// - [onSkewChange]：偏差是否超過 [clockSkewThreshold] 的變化串流，供提示橫幅
///   （比照離線橫幅）訂閱。
///
/// 用單調時鐘當錨點，是為了在**不需再發網路請求**的情況下也能重新評估偏差：
/// 使用者把時鐘改回正確時，週期性重評（[_reevalInterval]）會讓 [isSkewed]
/// 轉回 `false`、橫幅自動收合；反之亦然。未取得任何 `Date` header 前，[now]
/// 退化為裝置本地時間，行為與現況一致。
///
/// 注意：單調時鐘（[Stopwatch]）在 App 被系統凍結／裝置休眠期間**不會前進**，
/// 但牆上時鐘 `DateTime.now()` 照走真實時間。若 App 背景放置一段時間後恢復，
/// 舊錨點會失準（推算出的真實時間落後於實際），拿去比對就會誤判成「時間誤差
/// 過大」而彈出橫幅。為此 [startLifecycleWatch] 會監聽 App 生命週期，於進背景／
/// 恢復時作廢錨點，待恢復後第一個回應重新校準，避免這種假陽性。
class ServerTimeService with WidgetsBindingObserver {
  ServerTimeService._();
  static final ServerTimeService instance = ServerTimeService._();

  /// 單調計時來源：其 elapsed 不受系統牆上時鐘調整影響。
  final Stopwatch _sw = Stopwatch()..start();

  /// 最近一次量到的伺服器真實時間（UTC），以及量到當下的單調計時。
  DateTime? _serverAnchorUtc;
  Duration? _anchorElapsed;

  bool _isSkewed = false;
  Timer? _timer;
  final StreamController<bool> _skewController =
      StreamController<bool>.broadcast();

  /// 有錨點後，每隔這段時間重新評估一次偏差（讓使用者改回時鐘後橫幅能自動收合）。
  static const Duration _reevalInterval = Duration(seconds: 15);

  bool _observing = false;

  /// 開始監聽 App 生命週期，於背景／恢復時作廢陳舊錨點。由 `main()` 呼叫一次即可
  /// （重複呼叫為 no-op）。單調時鐘在背景凍結期間不前進，恢復後舊錨點會失準而
  /// 造成時間誤差橫幅假陽性——這裡在切換前後清掉錨點以避免之。
  void startLifecycleWatch() {
    if (_observing) return;
    _observing = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 進背景（paused／hidden）與恢復（resumed）都作廢：於 paused 清掉可避免恢復後
    // 週期性重評搶在生命週期回呼前用陳舊錨點誤判；resumed 再清一次作為保險。
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.resumed) {
      _invalidateAnchor();
    }
  }

  /// 作廢目前錨點並收合橫幅：清掉後 [now] 退化為 `DateTime.now()`、[_reevaluate]
  /// 在無錨點時直接跳過，待下一個回應的 `Date` header 重新校準。
  void _invalidateAnchor() {
    _serverAnchorUtc = null;
    _anchorElapsed = null;
    if (_isSkewed) {
      _isSkewed = false;
      _skewController.add(false);
    }
  }

  /// 由 client 的 `onResponse` 呼叫，餵入回應的 `Date` header 值。
  /// header 為 `null`／無法解析時忽略（不動先前的錨點）。
  void reportServerDate(String? header) {
    if (header == null) return;
    final serverUtc = parseHttpDate(header);
    if (serverUtc == null) return;

    _serverAnchorUtc = serverUtc;
    _anchorElapsed = _sw.elapsed;
    _timer ??= Timer.periodic(_reevalInterval, (_) => _reevaluate());
    _reevaluate();
  }

  /// 目前估計的真實時間（UTC），以錨點 + 單調計時推算。
  DateTime? _trueUtcNow() {
    final anchor = _serverAnchorUtc;
    final anchorElapsed = _anchorElapsed;
    if (anchor == null || anchorElapsed == null) return null;
    return anchor.add(_sw.elapsed - anchorElapsed);
  }

  /// 依目前裝置牆上時鐘與估計真實時間的差距，更新 [isSkewed] 並在有變化時發射。
  void _reevaluate() {
    final trueUtc = _trueUtcNow();
    if (trueUtc == null) return;
    final deviceSkew = DateTime.now().toUtc().difference(trueUtc);
    final skewed = deviceSkew.abs() > clockSkewThreshold;
    if (skewed != _isSkewed) {
      _isSkewed = skewed;
      _skewController.add(skewed);
    }
  }

  /// 台灣時區固定偏移 (UTC+8)。雲科是台灣的服務，時間顯示一律用台灣牆上時間，
  /// 不隨裝置時區設定改變。
  static const Duration _taipeiOffset = Duration(hours: 8);

  /// 校正後的真實時間（UTC instant）。供 nonce 等需要正確時間戳的用途；
  /// 尚未取得伺服器時間前，退化為裝置的 UTC 時鐘。
  DateTime trueUtcNow() => _trueUtcNow() ?? DateTime.now().toUtc();

  /// 校正後的現在時間，固定以**台灣時區 (UTC+8) 的牆上時間**呈現，
  /// **不受裝置時區設定影響**：即使使用者裝置時區設錯，行事曆「今天」與
  /// 課表紅線仍以台灣時間為準。回傳 local-flavour 的 [DateTime]（其
  /// 年/月/日/時分秒即台灣牆上時間），呼叫端沿用既有欄位讀取即可。
  DateTime now() {
    final tw = trueUtcNow().add(_taipeiOffset);
    return DateTime(
      tw.year,
      tw.month,
      tw.day,
      tw.hour,
      tw.minute,
      tw.second,
      tw.millisecond,
      tw.microsecond,
    );
  }

  /// 目前是否偏差過大（同步取現值，供 provider 種初值）。
  bool get isSkewed => _isSkewed;

  /// 偏差是否過大的變化串流（`true` = 誤差過大）。
  Stream<bool> get onSkewChange => _skewController.stream;
}
