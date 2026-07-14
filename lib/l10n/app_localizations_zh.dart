// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get settingsTitle => '設定';

  @override
  String get navOverview => '總覽';

  @override
  String get navSchedule => '課表';

  @override
  String get navInfo => '資訊';

  @override
  String get navCalendar => '行事曆';

  @override
  String get navSettings => '設定';

  @override
  String get languageSetting => '語言設定';

  @override
  String get appPrivacyPolicy => '雲科工具箱 隱私權政策';

  @override
  String get viewPolicyOnGithub => '在瀏覽器查看';

  @override
  String get termsUpdateTitle => '提示';

  @override
  String get termsUpdateAlert => '隱私權政策已更新，請同意後再繼續使用';

  @override
  String get continueLabel => '繼續';

  @override
  String get logout => '登出';

  @override
  String get reportIssue => '回報問題';

  @override
  String get reportChannelTitle => '選擇回報方式';

  @override
  String get reportViaEmail => '以 Email 回報';

  @override
  String get reportViaDiscord => '加入 Discord 社群回報';

  @override
  String get reportEmailSubject => '【雲科工具箱】問題回報';

  @override
  String reportEmailBody(String version, String platform) {
    return '請在此描述您遇到的問題：\n\n\n------\nApp 版本：$version\n平台：$platform';
  }

  @override
  String get reportLaunchError => '無法開啟，請稍後再試';

  @override
  String get installApp => '安裝 APP';

  @override
  String get notPromoted => '不再提示';

  @override
  String get ok => '好的';

  @override
  String get confirm => '確定';

  @override
  String get install => '安裝';

  @override
  String get profileDisclaimer => '※ 此頁面僅供參考，無法作為在學證明等正式用途';

  @override
  String get installError => '目前無法安裝：您可能已安裝，或瀏覽器不支援此功能';

  @override
  String get installTitle => '安裝 雲科工具箱 APP';

  @override
  String get installDescIos =>
      '將 雲科工具箱 捷徑安裝到您的裝置：\n\n1️⃣  點擊底部「分享」圖示 ⧧\n2️⃣  往下捲動，選擇「加入主畫面」\n3️⃣  點擊「加入」';

  @override
  String get installDescAndroid => '將 雲科工具箱 安裝到您的裝置，不用開啟瀏覽器即可直接操作。';

  @override
  String get vacationLabelWinter => '寒假';

  @override
  String get vacationLabelSummer => '暑假';

  @override
  String get vacationError => '無法顯示寒暑假時間';

  @override
  String get vacationCountdownPrefix => '還有';

  @override
  String get vacationCountdownPrefixSchool => '再';

  @override
  String get vacationCountdownSuffix => '天';

  @override
  String vacationElapsed(String percentage) {
    return '已度過 $percentage%';
  }

  @override
  String get vacationInfoTitle => '放假小卡說明';

  @override
  String get vacationInfoContent =>
      '倒數放假與開學的小卡。\n\n・上課期間 → 「再 X 天放假」\n・放假期間 → 「還有 X 天開學」\n\n進度條與底部百分比 = 目前階段「已度過」多少（0→100% 逐漸填滿）。\n\n小提醒：放假前若接著週末或國定假日，假期起點會提前到第一個放假日。';

  @override
  String get todayClassesTitle => '今日課程';

  @override
  String get notLoggedInMessage => '您尚未登入，請先登入以使用完整功能';

  @override
  String get noClassesToday => '今日無課程！';

  @override
  String get todayHolidayNote => '今日為放假日';

  @override
  String get upcomingEventsTitle => '近期校園行事曆';

  @override
  String get noUpcomingEvents => '近期無任何校園行事曆事項安排。';

  @override
  String get eventToday => '今天';

  @override
  String get eventTomorrow => '明天';

  @override
  String eventInDays(int days) {
    return '還有 $days 天';
  }

  @override
  String get noCourseDetail => '這門課沒有提供詳細課綱';

  @override
  String get notSpecified => '無資料';

  @override
  String classPeriods(String periods) {
    return '第 $periods 節';
  }

  @override
  String get loginToUseAllFeatures => '登入使用所有功能';

  @override
  String get goToLogin => '前往登入';

  @override
  String get loginUsernamePrompt => '請輸入學號';

  @override
  String get loginPasswordPrompt => '請輸入密碼';

  @override
  String get loginCaptchaPrompt => '請輸入驗證碼';

  @override
  String get loginHeading => '登入雲科單一入口服務網';

  @override
  String get loginUsernameLabel => '學號';

  @override
  String get loginPasswordLabel => '密碼';

  @override
  String get loginCaptchaLabel => '驗證碼';

  @override
  String get loginCaptchaRefreshTooltip => '重新整理驗證碼';

  @override
  String get loginShowPassword => '顯示密碼';

  @override
  String get loginHidePassword => '隱藏密碼';

  @override
  String get loginButton => '登入';

  @override
  String get loginFailed => '帳密或驗證碼錯誤';

  @override
  String get loginServiceUnavailable => '無法連線至單一入口服務網，請稍後再試';

  @override
  String get totpTitle => '二步驟驗證';

  @override
  String get totpPrompt => '請輸入驗證器 App（如 Google Authenticator）顯示的 6 位數驗證碼';

  @override
  String get totpCodeLabel => '驗證碼';

  @override
  String get totpVerifyButton => '驗證';

  @override
  String get totpCancel => '取消';

  @override
  String get totpFailed => '驗證碼錯誤，請重新登入';

  @override
  String get pleaseLoginToViewSchedule => '請在此登入以查看課表';

  @override
  String get mapModeEnabled => '已開啟地圖定位模式，點擊課程直接前往地圖';

  @override
  String get mapModeDisabled => '已關閉地圖定位模式';

  @override
  String get mapModeTooltip => '地圖定位模式';

  @override
  String get loadScheduleFailed => '無法載入課表';

  @override
  String get checkNetworkRetry => '請確認網路連線後重試';

  @override
  String serviceUnavailable(String service) {
    return '無法連線至$service，請確認網路，或稍後再試';
  }

  @override
  String get serviceGrades => '成績系統';

  @override
  String get serviceSchedule => '課表系統';

  @override
  String get serviceGraduation => '畢業審核系統';

  @override
  String get serviceAbsent => '請假系統';

  @override
  String get serviceCalendar => '學校行事曆';

  @override
  String get serviceCourseDetail => '課程大綱系統';

  @override
  String get serviceYunReport => '在學證明服務';

  @override
  String get retry => '重試';

  @override
  String get offlineBanner => '離線模式・顯示的是先前的快取資料';

  @override
  String get clockSkewBanner => '裝置時間誤差過大，可能導致異常，請校正系統時間';

  @override
  String get loginNoNetwork => '無法連線，請檢查網路後再試';

  @override
  String get noScheduleData => '目前沒有任何課表資料';

  @override
  String weekdayHeader(String day) {
    return '星期$day';
  }

  @override
  String get weekdayMon => '一';

  @override
  String get weekdayTue => '二';

  @override
  String get weekdayWed => '三';

  @override
  String get weekdayThu => '四';

  @override
  String get weekdayFri => '五';

  @override
  String get weekdaySat => '六';

  @override
  String get weekdaySun => '日';

  @override
  String get periodHeader => '節';

  @override
  String periodDetails(String period, String time) {
    return '第 $period 節：$time';
  }

  @override
  String get noClassroomForLocation => '此課程無指定教室，無法定位';

  @override
  String classroomLabel(String room) {
    return '教室: $room';
  }

  @override
  String teacherLabel(String teacher) {
    return '教師: $teacher';
  }

  @override
  String timeLabel(String time) {
    return '時段: $time';
  }

  @override
  String get close => '關閉';

  @override
  String get notDecided => '未定';

  @override
  String get infoTitle => '資訊';

  @override
  String get infoGradesTitle => '成績查詢';

  @override
  String get infoGradesDesc => '查詢學期與歷年成績及班級排名';

  @override
  String get infoGradTitle => '畢業學分';

  @override
  String get infoGradDesc => '檢視畢業門檻與修課學分進度';

  @override
  String get infoMapTitle => '校園地圖';

  @override
  String get infoMapDesc => '查看校園地圖，提供搜尋功能快速查看系館位置';

  @override
  String get infoYunReportTitle => '在學證明';

  @override
  String get infoYunReportDesc => '檢視本學期在學證明';

  @override
  String get infoAbsentTitle => '請假記錄';

  @override
  String get infoAbsentDesc => '查詢各學年期的請假申請與簽核狀態';

  @override
  String get absentLoadFailed => '載入請假記錄失敗';

  @override
  String get absentEmpty => '這個學年期沒有請假記錄';

  @override
  String absentHours(String hours) {
    return '請假時數 $hours 小時';
  }

  @override
  String get infoCommonLinks => '常用連結';

  @override
  String get yunReportUnavailable => '無法取得在學證明，請稍後再試。';

  @override
  String get yunReportNotRegistered => '尚未完成本學期註冊，暫時無法提供在學證明。';

  @override
  String get yunReportRetry => '重試';

  @override
  String get yunReportNoteDisplay => '僅提供顯示證明使用，如有疑問請洽教務處註冊組。';

  @override
  String get yunReportNotePaper => '如需紙本，請向教務處註冊組提出申請，勿擅自列印。';

  @override
  String get loginRememberPassword => '記住密碼';

  @override
  String get loginRememberPasswordHint => '供下列功能使用，密碼以雜湊形式儲存於本機中，未勾選不影響其他功能使用。';

  @override
  String get loginRememberPasswordWarning => '如未記住密碼，當憑證失效時，會無法自動登入。';

  @override
  String get loginRememberPasswordScope => '使用範圍：';

  @override
  String get appAuthRequiredTitle => '需要重新驗證';

  @override
  String get appAuthRequiredMessage => '此功能的授權已過期，請重新輸入密碼以繼續使用。';

  @override
  String get appAuthUnlock => '驗證';

  @override
  String get appAuthCancel => '取消';

  @override
  String get appAuthWrongPassword => '密碼錯誤，請重新輸入。';

  @override
  String get changePasswordTitle => '變更密碼';

  @override
  String get changePasswordOldLabel => '現在的密碼';

  @override
  String get changePasswordNewLabel => '新密碼';

  @override
  String get changePasswordConfirmLabel => '確認新密碼';

  @override
  String get changePasswordRule => '密碼僅可含 A-Z、a-z、0-9 及 @!\$%&*，不得含空白';

  @override
  String get changePasswordHint =>
      '修改密碼後，將一併修改 Microsoft 365 與 Google Workspace 之密碼，請記住新密碼。\n使用此處修改密碼後，本應用程式將自動使用新密碼重新登入。';

  @override
  String get changePasswordButton => '確認並儲存';

  @override
  String get changePasswordEmpty => '請填寫所有欄位';

  @override
  String get changePasswordMismatch => '兩次輸入的新密碼不一致';

  @override
  String get changePasswordInvalidChars =>
      '新密碼只能包含 A-Z、a-z、0-9 及 @!\$%&*，且不得含空白';

  @override
  String get changePasswordSuccess => '密碼已變更';

  @override
  String get changePasswordFailed => '密碼變更失敗，請稍後再試';

  @override
  String get credentialTitle => '應用程式憑證';

  @override
  String get credentialStatusTitle => '憑證狀態';

  @override
  String get credentialStatusValid => '有效';

  @override
  String get credentialStatusNone => '尚未取得';

  @override
  String get credentialExpiryLabel => '有效期限：';

  @override
  String get credentialExpiryUnknown => '有效期限未知';

  @override
  String credentialDaysRemaining(int days) {
    return '約剩 $days 天';
  }

  @override
  String get credentialEnableRememberTitle => '啟用記住密碼';

  @override
  String get credentialEnableRememberMessage =>
      '請輸入密碼以啟用記住密碼。往後此憑證過期時會自動更新，不需再手動輸入。';

  @override
  String get credentialClearOnRestartHint =>
      '已取消記住密碼。基於安全考量，本機儲存的密碼將於下次重新啟動應用程式時清除。';

  @override
  String get credentialFeaturesTitle => '使用此憑證的功能';

  @override
  String get credentialAbout =>
      '部分功能會使用雲科行動 App 的端點，需要一組額外的登入憑證。當憑證過期後若你已記住密碼，App 會自動重新取得憑證；若未記住密碼，使用憑證相關功能時，會請你重新輸入一次密碼。\n密碼僅以雜湊形式儲存於本機安全儲存區，無法還原為明文，也無法用於網頁登入。';

  @override
  String get calendarTitle => '行事曆';

  @override
  String get legendTitle => '行事曆圖示說明';

  @override
  String get legendBgColor => '日期背景顏色：';

  @override
  String get legendToday => '今天日期';

  @override
  String get legendSelected => '當前選取日期';

  @override
  String get legendHoliday => '國定假日';

  @override
  String get legendVacation => '寒假 / 暑假';

  @override
  String get legendDots => '事件小點點：';

  @override
  String get legendEvent => '一般事件';

  @override
  String get legendImportant => '重要事件';

  @override
  String get noEventsToday => '本日無行程';

  @override
  String get legendTooltip => '圖示說明';

  @override
  String get backToTodayTooltip => '回到今日';

  @override
  String get loadCalendarFailed => '載入失敗';

  @override
  String get gradesTitle => '成績查詢';

  @override
  String get gradesSegmentSemester => '學期';

  @override
  String get gradesSegmentHistory => '歷年';

  @override
  String get gradesNoData => '尚無成績資料';

  @override
  String get gradesNoHistoryData => '尚無歷年成績資料';

  @override
  String get gradesNoCurrentData => '尚無當前學期的成績資料';

  @override
  String get gradesNotEnrolled => '（已畢業或本學期未在學）';

  @override
  String get loadGradesFailed => '無法載入成績';

  @override
  String get pleaseLoginToViewGrades => '請在此登入以查看成績';

  @override
  String get gradesAverage => '平均成績';

  @override
  String get gradesRank => '班級排名';

  @override
  String get gradesEarnedCredits => '實得學分';

  @override
  String get gradesGPA => 'GPA';

  @override
  String gradesGPAShort(String gpa) {
    return 'GPA: $gpa';
  }

  @override
  String gradesAverageShort(String avg) {
    return '平均: $avg';
  }

  @override
  String gradesRankShort(String rank) {
    return '排名: $rank';
  }

  @override
  String gradesCreditsShort(String credits) {
    return '學分: $credits';
  }

  @override
  String courseCreditsFormat(String credits) {
    return '$credits 學分';
  }

  @override
  String gradesSemesterTitle(String year, String semester) {
    return '$year學年 第$semester學期';
  }

  @override
  String get courseInstructor => '授課教師';

  @override
  String get courseContactInfo => '聯絡資訊';

  @override
  String get courseCurriculumNo => '系所課號';

  @override
  String get courseCredits => '學分數';

  @override
  String get courseScheduleClassroom => '上課時間教室';

  @override
  String get courseClass => '開課班級';

  @override
  String get scheduleNoTimeTitle => '無安排上課時間';

  @override
  String get courseRequiredElective => '修別';

  @override
  String get courseType => '授課方式';

  @override
  String get courseRemark => '備註';

  @override
  String get courseGoal => '教學目標';

  @override
  String get courseOutline => '課程大綱';

  @override
  String get courseGrading => '成績評量方式';

  @override
  String get courseSyllabus => '教學計畫與進度';

  @override
  String get courseNoData => '無資料';

  @override
  String get courseNone => '無';

  @override
  String get courseOpenInBrowser => '在瀏覽器開啟';

  @override
  String get courseSelectRoomLocation => '選擇上課教室定位';

  @override
  String courseGoToRoomLocation(String room) {
    return '前往 $room 定位';
  }

  @override
  String get courseInvalidRoomCode => '教室代號格式無效，無法定位';

  @override
  String courseBuildingNotFound(String prefix) {
    return '查無大樓 [$prefix] 的定位資訊';
  }

  @override
  String get courseLoadMapDataFailed => '讀取地圖資料失敗';

  @override
  String get gradLoadFailed => '無法載入畢業學分';

  @override
  String get gradNoData => '尚無畢業學分資料';

  @override
  String get gradDetailTitle => '學分統計詳細';

  @override
  String get gradTotalNotice => '* 合計欄位為通識 + 必修 + 選修';

  @override
  String get gradMissingRequiredCourses => '未修通過必修課';

  @override
  String get gradTotalEarnedCredits => '總實得學分';

  @override
  String get gradEnglishThreshold => '英文門檻';

  @override
  String get gradInternshipThreshold => '實習門檻';

  @override
  String get gradCategory => '類別';

  @override
  String get gradRequired => '應修';

  @override
  String get gradEarned => '實得';

  @override
  String get gradMissing => '尚缺';

  @override
  String gradYearFormat(String year) {
    return '$year年級';
  }

  @override
  String get gradLabelPE => '體育';

  @override
  String get gradLabelCivilization => '文明';

  @override
  String get gradLabelLiterature => '文學';

  @override
  String get gradLabelGeneral => '通識';

  @override
  String get gradLabelDeptRequired => '必修';

  @override
  String get gradLabelElective => '選修';

  @override
  String get gradLabelTotal => '合計';

  @override
  String get mapLoadingText => '正在繪製向量校園地圖...';

  @override
  String get mapSearchHint => '搜尋系館名稱或代號';

  @override
  String mapQueryRoom(String room) {
    return '查詢教室：$room';
  }

  @override
  String get mapNoDescription => '暫無此建築物之詳細介紹。';

  @override
  String get mapNavigateButton => '導航到這裡';

  @override
  String get mapNavigateFailed => '無法開啟地圖應用程式';

  @override
  String get mapResetView => '重置地圖檢視';

  @override
  String get mapFloorPlanUnderConstruction => '平面圖建置中';

  @override
  String mapFloorPlanUnavailable(String room) {
    return '$room 平面圖不可用';
  }

  @override
  String get updateLater => '稍後';

  @override
  String get updateReadyTitle => '更新已就緒';

  @override
  String get updateReadyBody => '新版本已下載完成，重新啟動即可完成安裝。';

  @override
  String get updateRestart => '重新啟動';

  @override
  String get webViewOpenInBrowser => '用外部瀏覽器開啟';

  @override
  String get webViewCopyLink => '複製連結';

  @override
  String get webViewLinkCopied => '已複製連結至剪貼簿';

  @override
  String get webViewLoadFailed => '網頁載入失敗';

  @override
  String get webViewRefresh => '重新整理';

  @override
  String get profileMinorDoubleMajor => '輔系/雙主修';

  @override
  String get profileProgram => '學程';

  @override
  String get profileTeacherEducation => '教育學程';

  @override
  String get settingsGradeNotification => '成績更新通知';

  @override
  String get settingsGradeNotificationSub => '背景每 30 分鐘檢查一次成績';

  @override
  String get notificationPermissionDenied => '無法開啟通知：請前往系統設定啟用通知權限';

  @override
  String gradeNotifyScoreBody(String score) {
    return '成績更新：$score 分';
  }

  @override
  String get gradeNotifyRankTitle => '學期排名';

  @override
  String gradeNotifyRankBody(String rank) {
    return '排名：$rank';
  }

  @override
  String get gradeNotifyGpaTitle => '學期 GPA';

  @override
  String gradeNotifyGpaBody(String gpa) {
    return 'GPA 更新：$gpa';
  }

  @override
  String get gradeNotifyAvgTitle => '學期平均';

  @override
  String gradeNotifyAvgBody(String avg) {
    return '平均更新：$avg 分';
  }

  @override
  String get termsAgree => '同意';

  @override
  String get termsRejectAndExit => '拒絕並退出程式';

  @override
  String termsLastUpdated(String date) {
    return '最後更新日期：$date';
  }

  @override
  String get refresh => '重新整理';
}
