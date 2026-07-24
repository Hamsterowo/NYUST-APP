// RefreshOutcome 的定義已移至中立的 `services/scrape_result.dart`（供 scraper
// 型別化回傳時共用，避免 scraper 反向依賴 repository 層）。此檔 re-export 該
// enum 以維持既有 import 路徑不變，並保留 repository 專用的 classifyRefreshFailure。
import '../services/scrape_result.dart';

export '../services/scrape_result.dart' show RefreshOutcome, RefreshOutcomeX;

/// 從 scraper 回應的 `status` 判別碼歸類失敗原因。
/// （仍用於尚未型別化的 getSchedule / getGraduation 等回傳 Map 的路徑。）
RefreshOutcome classifyRefreshFailure(Map<String, dynamic> resp) {
  switch (resp['status']?.toString()) {
    case 'network_error':
      return RefreshOutcome.networkError;
    case 'session_expired':
      return RefreshOutcome.sessionExpired;
    default:
      return RefreshOutcome.serviceError;
  }
}
