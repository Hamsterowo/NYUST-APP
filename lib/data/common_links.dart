/// 資訊頁「常用連結」的資料來源。
///
/// **新增／刪除連結只要改這份 [kCommonLinks] 清單即可**——資訊頁的常用連結
/// 區塊會自動把每一筆排成「兩個一排」的按鈕，不需要改任何排版程式碼。
///
/// 連結若指向 `webapp.yuntech.edu.tw` 的頁面，會由內建瀏覽器帶入登入 cookie
/// （見 `AppWebViewScreen`），因此點進去通常已是登入狀態。
class CommonLink {
  /// 中文標題（按鈕文字）。
  final String title;

  /// 英文標題（可省略；省略時英文介面也顯示中文標題）。
  final String? titleEn;

  /// 目標網址。
  final String url;

  const CommonLink({required this.title, this.titleEn, required this.url});
}

/// 常用連結清單。要新增／刪除連結，直接改這個清單即可。
const List<CommonLink> kCommonLinks = [
  CommonLink(
    title: '學生居住情形登陸',
    titleEn: 'Housing Registration',
    url: 'https://webapp.yuntech.edu.tw/AsxServ/StudDorm/Index',
  ),
  CommonLink(
    title: '學生請假系統',
    titleEn: 'Leave System',
    url:
        'https://webapp.yuntech.edu.tw/WebASXASG/StudAbsentApp/StudAbsentAppQry.aspx',
  ),
  CommonLink(
    title: '選課系統',
    titleEn: 'Course Selection',
    url: 'https://webapp.yuntech.edu.tw/AAXCCS/CourseSelectionRegister.aspx',
  ),
];
