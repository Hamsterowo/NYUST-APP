// Scraper / 資料抓取的結果分類與型別化信封。
//
// 這是三個型別化票（成績 / 畢業門檻 / 課表）共用的地基，放在中立的 services 層，
// 讓 scraper 回傳型別化結果時不必反向依賴 repository 層。
// RefreshOutcome 原本住在 `repositories/refresh_outcome.dart`，現移至此處，
// 該檔改為 re-export 並保留 `classifyRefreshFailure`（仍是 repository 職責）。

/// Repository `refresh()` 與 scraper 抓取的結果分類。
///
/// UI 據此決定錯誤文案：[networkError] 顯示具名的「無法連線至XX系統」，
/// [serviceError] 顯示通用載入失敗；[sessionExpired] 目前僅記錄（登出決策
/// 仍由 InfoScraper 的 session_expired 單一來源負責，見 CLAUDE.md 紅線）。
enum RefreshOutcome { success, networkError, serviceError, sessionExpired }

extension RefreshOutcomeX on RefreshOutcome {
  bool get isSuccess => this == RefreshOutcome.success;
}

/// 抓取結果的型別化信封：成功帶著型別化的 [data]，失敗帶著失敗分類 [status]。
///
/// 取代過去 scraper 回傳的 `Map<String, dynamic>`（`success` / `status` 判別碼）。
class ScrapeResult<T> {
  final RefreshOutcome status;
  final T? data;

  const ScrapeResult.success(T this.data) : status = RefreshOutcome.success;

  const ScrapeResult.failure(this.status) : data = null;

  bool get isSuccess => status.isSuccess;
}
