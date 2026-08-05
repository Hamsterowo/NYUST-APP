/// Web（以及任何沒有檔案系統的目標）：不支援，呼叫端在此之前就該擋掉。
///
/// 之所以還是丟例外而不是靜靜地什麼都不做：真的被呼叫到就代表 `isSupported`
/// 的判斷跟這裡對不上，那是個 bug，不該偽裝成「按了沒反應」。
Future<void> openIcsFile(String icsText, {required String filename}) {
  throw UnsupportedError('Adding to the system calendar is not supported here');
}
