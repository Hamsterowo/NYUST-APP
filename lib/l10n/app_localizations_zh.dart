// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'NYUST+';

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
  String get languageSettingSub => '至系統設定修改 App 語言';

  @override
  String get privacyPolicy => 'YunTech 單一入口隱私權政策';

  @override
  String get termsOfService => 'NYUST+ 使用者條款';

  @override
  String get logout => '登出';

  @override
  String get reportIssue => '回報問題';

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
  String get featureNotFinished => '此功能尚未完成';

  @override
  String get installTitle => '安裝 NYUST+ APP';

  @override
  String get installDescIos =>
      '將 NYUST+ 捷徑安裝到您的裝置：\n\n1️⃣  點擊底部「分享」圖示 ⧧\n2️⃣  往下捲動，選擇「加入主畫面」\n3️⃣  點擊「加入」';

  @override
  String get installDescAndroid => '將 NYUST+ 安裝到您的裝置，不用開啟瀏覽器即可直接操作。';

  @override
  String get vacationLabelStart => '開學';

  @override
  String get vacationLabelWinter => '寒假';

  @override
  String get vacationLabelSummer => '暑假';

  @override
  String get vacationError => '無法顯示寒暑假時間';

  @override
  String get vacationCountdownPrefix => '還有';

  @override
  String get vacationCountdownSuffix => '天';

  @override
  String vacationElapsed(String percentage) {
    return '已度過 $percentage%';
  }

  @override
  String get todayClassesTitle => '今日課程';

  @override
  String get notLoggedInMessage => '您尚未登入，請先登入以使用完整功能';

  @override
  String get noClassesToday => '今日無課程！';

  @override
  String get upcomingEventsTitle => '近期校園行事曆';

  @override
  String get noUpcomingEvents => '近期無任何校園行事曆事項安排。';

  @override
  String get noCourseDetail => '這門課沒有提供詳細課綱';

  @override
  String get notSpecified => '未指定';

  @override
  String classPeriods(String periods) {
    return '第 $periods 節';
  }

  @override
  String get loginToUseAllFeatures => '登入使用所有功能';

  @override
  String get goToLogin => '前往登入';

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
  String get retry => '重試';

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
  String loadErrorPrefix(String error) {
    return '發生錯誤：$error';
  }

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
  String get gradesDetailHeader => '本學期修課成績明細';

  @override
  String get gradesAllDetailHeader => '修課成績明細';

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
  String get courseOpenWebpageFailed => '無法開啟網頁';

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
  String courseLoadMapDataFailed(String error) {
    return '讀取地圖資料失敗: $error';
  }

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
  String get mapExternalNav => '外部地圖導航';

  @override
  String get mapFloorPlanUnderConstruction => '平面圖建置中';

  @override
  String mapFloorPlanUnavailable(String room) {
    return '$room 平面圖不可用';
  }
}
