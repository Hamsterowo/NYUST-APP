/// 資料畫面在「更新」期間該呈現的四種形態。
enum RefreshBodyState {
  /// 骨架：主動更新中，或從未成功載入且尚未失敗。
  skeleton,

  /// 錯誤頁：從未成功載入且已失敗。
  error,

  /// 空狀態：載入成功但零筆。
  empty,

  /// 內容列表。
  list,
}

/// 決定資料畫面該顯示哪一種形態。
///
/// [isEmpty] 用三態表達「有沒有資料可顯示」：`null` 代表從未成功載入，`true`
/// 代表載入成功但零筆，`false` 代表有內容。取自集合時直接寫 `records?.isEmpty`。
///
/// [manualRefreshing] 排在最前面，就是「使用者按的更新一律顯示骨架」這條規則。
/// 它是**覆蓋**而非取代——更新期間底下的資料原封不動，因此旗標一清，畫面自己就
/// 回到原先的形態，「失敗時回到原先顯示的畫面」不需要任何還原邏輯。
RefreshBodyState resolveRefreshBody({
  required bool? isEmpty,
  required bool failed,
  required bool manualRefreshing,
}) {
  if (manualRefreshing) return RefreshBodyState.skeleton;
  if (isEmpty == null) {
    return failed ? RefreshBodyState.error : RefreshBodyState.skeleton;
  }
  return isEmpty ? RefreshBodyState.empty : RefreshBodyState.list;
}
