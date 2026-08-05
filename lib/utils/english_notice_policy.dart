/// 英文語系提示的觸發原因；[none] 表示這次不該跳。
enum EnglishNoticeTrigger {
  none,

  /// 開 App 時畫面上本來就是英文（使用者沒切換過任何東西）。
  coldStart,

  /// 使用者的動作讓畫面從非英文變成英文。
  switched,
}

/// 「這次該不該跳英文語系提示、要不要記下已讀」的純函式判定。
///
/// 整個功能所有會判斷錯的東西都收在這裡 —— 語系字串的正規化、冷啟動與切換兩條
/// 路徑的節流差異、已讀旗標該不該寫 —— 外層（讀寫 SharedPreferences、等開場
/// 動畫、呼叫 showDialog）都是無邏輯的膠水，因此這裡是唯一的測試接縫。
class EnglishNoticePolicy {
  EnglishNoticePolicy._();

  /// 判定這次是否該跳提示。
  ///
  /// [previousLocale] 為 `null` 表示本次 session 還沒套用過語系，也就是冷啟動的
  /// 第一次判定。呼叫端必須等語言設定讀完才開始餵值：開機時讀完設定前畫面上的
  /// 語系只是「跟隨系統」的暫定值，把那次 settle 當成使用者切換語言，等於每次
  /// 開機都跳一次。
  ///
  /// 兩個語系參數收完整字串（`'en'`、`'en_US'`、`'zh_TW'`…），內部取 `_` / `-`
  /// 前段正規化後比對 `'en'`，所以呼叫端可以直接餵主畫面既有的 `_appliedLocale`。
  ///
  /// [alreadyShown] 是持久化的已讀旗標；回傳的 `shouldPersist` 為 true 時呼叫端
  /// 才需要寫入（重複寫沒有意義，也讓「這次是不是第一次」在紀錄上失真）。
  ///
  /// 規則唯一不對稱的地方是 [EnglishNoticeTrigger.switched] 不看 [alreadyShown]：
  /// 切換語言是使用者主動造成的，當下給回饋一定對；冷啟動是被動狀態，重複跳只會
  /// 讓這則靜態聲明退化成雜訊，所以只跳一次。
  static ({EnglishNoticeTrigger trigger, bool shouldPersist}) decide({
    String? previousLocale,
    required String currentLocale,
    required bool alreadyShown,
  }) {
    if (!_isEnglish(currentLocale)) {
      return (trigger: EnglishNoticeTrigger.none, shouldPersist: false);
    }

    if (previousLocale == null) {
      return alreadyShown
          ? (trigger: EnglishNoticeTrigger.none, shouldPersist: false)
          : (trigger: EnglishNoticeTrigger.coldStart, shouldPersist: true);
    }

    // 英文 → 英文：使用者按了什麼不重要，畫面上的語言沒有變（例如已是 English
    // 又改成「跟隨系統」而系統也是英文）。
    if (_isEnglish(previousLocale)) {
      return (trigger: EnglishNoticeTrigger.none, shouldPersist: false);
    }

    return (
      trigger: EnglishNoticeTrigger.switched,
      shouldPersist: !alreadyShown,
    );
  }

  /// 語系字串是否為英文。取地區碼之前的語言碼比對，`'en'`、`'en_US'`、`'en-GB'`
  /// 都算英文。
  static bool _isEnglish(String locale) {
    final separator = locale.indexOf(RegExp(r'[_-]'));
    final language = separator < 0 ? locale : locale.substring(0, separator);
    return language.toLowerCase() == 'en';
  }
}
