import 'package:connectivity_plus/connectivity_plus.dart';

/// 連線狀態服務：把 connectivity_plus 的 [ConnectivityResult] 清單
/// 收斂成單純的 `bool`（是否有任一可用網路介面）。
///
/// 注意：這只反映「裝置有沒有連上網路介面」，不保證真的連得到學校伺服器。
/// 因此它只用於 UX（離線橫幅、跳過不必要的啟動驗證、恢復連線時重抓），
/// **實際的登出判斷仍以請求結果為準**（見 network_error / session_expired）。
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  static bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// 即時查詢目前是否在線上。查詢失敗時保守回傳 `true`（避免誤判離線而卡住流程）。
  Future<bool> checkOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isOnline(results);
    } catch (_) {
      return true;
    }
  }

  /// 線上狀態變化串流（`true` = 在線）。
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_isOnline);
}
