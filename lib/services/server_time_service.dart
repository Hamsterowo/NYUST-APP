import 'dart:async';

import '../utils/clock_drift.dart';

/// 全 App 共用的「可信任時間」服務。
///
/// 從每個 HTTP 回應都自帶的 `Date` header 取得伺服器 UTC 時間，並以**單調時鐘**
/// （[Stopwatch]，不受使用者改動裝置牆上時鐘影響）當錨點推算「真實時間」，
/// 對外提供：
/// - [now]：校正後的現在時間，供課表紅線、行事曆「今天」、nonce 等使用，
///   讓裝置時鐘偏差時仍顯示/送出正確時間。
/// - [onSkewChange]：偏差是否超過 [clockSkewThreshold] 的變化串流，供提示橫幅
///   （比照離線橫幅）訂閱。
///
/// 用單調時鐘當錨點，是為了在**不需再發網路請求**的情況下也能重新評估偏差：
/// 使用者把時鐘改回正確時，週期性重評（[_reevalInterval]）會讓 [isSkewed]
/// 轉回 `false`、橫幅自動收合；反之亦然。未取得任何 `Date` header 前，[now]
/// 退化為裝置本地時間，行為與現況一致。
class ServerTimeService {
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

  /// 校正後的現在時間（本地時區）。尚未取得伺服器時間前，退化為 `DateTime.now()`。
  DateTime now() => _trueUtcNow()?.toLocal() ?? DateTime.now();

  /// 目前是否偏差過大（同步取現值，供 provider 種初值）。
  bool get isSkewed => _isSkewed;

  /// 偏差是否過大的變化串流（`true` = 誤差過大）。
  Stream<bool> get onSkewChange => _skewController.stream;
}
