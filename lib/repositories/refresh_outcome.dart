/// Repository `refresh()` 的結果分類。
///
/// UI 據此決定錯誤文案：[networkError] 顯示具名的「無法連線至XX系統」，
/// [serviceError] 顯示通用載入失敗；[sessionExpired] 目前僅記錄（登出決策
/// 仍由 InfoScraper 的 session_expired 單一來源負責，見 CLAUDE.md 紅線）。
enum RefreshOutcome { success, networkError, serviceError, sessionExpired }

extension RefreshOutcomeX on RefreshOutcome {
  bool get isSuccess => this == RefreshOutcome.success;
}

/// 從 scraper 回應的 `status` 判別碼歸類失敗原因。
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
