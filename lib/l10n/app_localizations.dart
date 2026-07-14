import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get settingsTitle;

  /// No description provided for @navOverview.
  ///
  /// In zh, this message translates to:
  /// **'總覽'**
  String get navOverview;

  /// No description provided for @navSchedule.
  ///
  /// In zh, this message translates to:
  /// **'課表'**
  String get navSchedule;

  /// No description provided for @navInfo.
  ///
  /// In zh, this message translates to:
  /// **'資訊'**
  String get navInfo;

  /// No description provided for @navCalendar.
  ///
  /// In zh, this message translates to:
  /// **'行事曆'**
  String get navCalendar;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get navSettings;

  /// No description provided for @languageSetting.
  ///
  /// In zh, this message translates to:
  /// **'語言設定'**
  String get languageSetting;

  /// No description provided for @appPrivacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'雲科工具箱 隱私權政策'**
  String get appPrivacyPolicy;

  /// No description provided for @viewPolicyOnGithub.
  ///
  /// In zh, this message translates to:
  /// **'在瀏覽器查看'**
  String get viewPolicyOnGithub;

  /// No description provided for @termsUpdateTitle.
  ///
  /// In zh, this message translates to:
  /// **'提示'**
  String get termsUpdateTitle;

  /// No description provided for @termsUpdateAlert.
  ///
  /// In zh, this message translates to:
  /// **'隱私權政策已更新，請同意後再繼續使用'**
  String get termsUpdateAlert;

  /// No description provided for @continueLabel.
  ///
  /// In zh, this message translates to:
  /// **'繼續'**
  String get continueLabel;

  /// No description provided for @logout.
  ///
  /// In zh, this message translates to:
  /// **'登出'**
  String get logout;

  /// No description provided for @reportIssue.
  ///
  /// In zh, this message translates to:
  /// **'回報問題'**
  String get reportIssue;

  /// No description provided for @reportChannelTitle.
  ///
  /// In zh, this message translates to:
  /// **'選擇回報方式'**
  String get reportChannelTitle;

  /// No description provided for @reportViaEmail.
  ///
  /// In zh, this message translates to:
  /// **'以 Email 回報'**
  String get reportViaEmail;

  /// No description provided for @reportViaDiscord.
  ///
  /// In zh, this message translates to:
  /// **'加入 Discord 社群回報'**
  String get reportViaDiscord;

  /// No description provided for @reportEmailSubject.
  ///
  /// In zh, this message translates to:
  /// **'【雲科工具箱】問題回報'**
  String get reportEmailSubject;

  /// No description provided for @reportEmailBody.
  ///
  /// In zh, this message translates to:
  /// **'請在此描述您遇到的問題：\n\n\n------\nApp 版本：{version}\n平台：{platform}'**
  String reportEmailBody(String version, String platform);

  /// No description provided for @reportLaunchError.
  ///
  /// In zh, this message translates to:
  /// **'無法開啟，請稍後再試'**
  String get reportLaunchError;

  /// No description provided for @installApp.
  ///
  /// In zh, this message translates to:
  /// **'安裝 APP'**
  String get installApp;

  /// No description provided for @notPromoted.
  ///
  /// In zh, this message translates to:
  /// **'不再提示'**
  String get notPromoted;

  /// No description provided for @ok.
  ///
  /// In zh, this message translates to:
  /// **'好的'**
  String get ok;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'確定'**
  String get confirm;

  /// No description provided for @install.
  ///
  /// In zh, this message translates to:
  /// **'安裝'**
  String get install;

  /// No description provided for @profileDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'※ 此頁面僅供參考，無法作為在學證明等正式用途'**
  String get profileDisclaimer;

  /// No description provided for @installError.
  ///
  /// In zh, this message translates to:
  /// **'目前無法安裝：您可能已安裝，或瀏覽器不支援此功能'**
  String get installError;

  /// No description provided for @installTitle.
  ///
  /// In zh, this message translates to:
  /// **'安裝 雲科工具箱 APP'**
  String get installTitle;

  /// No description provided for @installDescIos.
  ///
  /// In zh, this message translates to:
  /// **'將 雲科工具箱 捷徑安裝到您的裝置：\n\n1️⃣  點擊底部「分享」圖示 ⧧\n2️⃣  往下捲動，選擇「加入主畫面」\n3️⃣  點擊「加入」'**
  String get installDescIos;

  /// No description provided for @installDescAndroid.
  ///
  /// In zh, this message translates to:
  /// **'將 雲科工具箱 安裝到您的裝置，不用開啟瀏覽器即可直接操作。'**
  String get installDescAndroid;

  /// No description provided for @vacationLabelWinter.
  ///
  /// In zh, this message translates to:
  /// **'寒假'**
  String get vacationLabelWinter;

  /// No description provided for @vacationLabelSummer.
  ///
  /// In zh, this message translates to:
  /// **'暑假'**
  String get vacationLabelSummer;

  /// No description provided for @vacationError.
  ///
  /// In zh, this message translates to:
  /// **'無法顯示寒暑假時間'**
  String get vacationError;

  /// No description provided for @vacationCountdownPrefix.
  ///
  /// In zh, this message translates to:
  /// **'還有'**
  String get vacationCountdownPrefix;

  /// No description provided for @vacationCountdownPrefixSchool.
  ///
  /// In zh, this message translates to:
  /// **'再'**
  String get vacationCountdownPrefixSchool;

  /// No description provided for @vacationCountdownSuffix.
  ///
  /// In zh, this message translates to:
  /// **'天'**
  String get vacationCountdownSuffix;

  /// No description provided for @vacationElapsed.
  ///
  /// In zh, this message translates to:
  /// **'已度過 {percentage}%'**
  String vacationElapsed(String percentage);

  /// No description provided for @vacationInfoTitle.
  ///
  /// In zh, this message translates to:
  /// **'放假小卡說明'**
  String get vacationInfoTitle;

  /// No description provided for @vacationInfoContent.
  ///
  /// In zh, this message translates to:
  /// **'倒數放假與開學的小卡。\n\n・上課期間 → 「再 X 天放假」\n・放假期間 → 「還有 X 天開學」\n\n進度條與底部百分比 = 目前階段「已度過」多少（0→100% 逐漸填滿）。\n\n小提醒：放假前若接著週末或國定假日，假期起點會提前到第一個放假日。'**
  String get vacationInfoContent;

  /// No description provided for @todayClassesTitle.
  ///
  /// In zh, this message translates to:
  /// **'今日課程'**
  String get todayClassesTitle;

  /// No description provided for @notLoggedInMessage.
  ///
  /// In zh, this message translates to:
  /// **'您尚未登入，請先登入以使用完整功能'**
  String get notLoggedInMessage;

  /// No description provided for @noClassesToday.
  ///
  /// In zh, this message translates to:
  /// **'今日無課程！'**
  String get noClassesToday;

  /// No description provided for @todayHolidayNote.
  ///
  /// In zh, this message translates to:
  /// **'今日為放假日'**
  String get todayHolidayNote;

  /// No description provided for @upcomingEventsTitle.
  ///
  /// In zh, this message translates to:
  /// **'近期校園行事曆'**
  String get upcomingEventsTitle;

  /// No description provided for @noUpcomingEvents.
  ///
  /// In zh, this message translates to:
  /// **'近期無任何校園行事曆事項安排。'**
  String get noUpcomingEvents;

  /// No description provided for @eventToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get eventToday;

  /// No description provided for @eventTomorrow.
  ///
  /// In zh, this message translates to:
  /// **'明天'**
  String get eventTomorrow;

  /// No description provided for @eventInDays.
  ///
  /// In zh, this message translates to:
  /// **'還有 {days} 天'**
  String eventInDays(int days);

  /// No description provided for @noCourseDetail.
  ///
  /// In zh, this message translates to:
  /// **'這門課沒有提供詳細課綱'**
  String get noCourseDetail;

  /// No description provided for @notSpecified.
  ///
  /// In zh, this message translates to:
  /// **'無資料'**
  String get notSpecified;

  /// No description provided for @classPeriods.
  ///
  /// In zh, this message translates to:
  /// **'第 {periods} 節'**
  String classPeriods(String periods);

  /// No description provided for @loginToUseAllFeatures.
  ///
  /// In zh, this message translates to:
  /// **'登入使用所有功能'**
  String get loginToUseAllFeatures;

  /// No description provided for @goToLogin.
  ///
  /// In zh, this message translates to:
  /// **'前往登入'**
  String get goToLogin;

  /// No description provided for @loginUsernamePrompt.
  ///
  /// In zh, this message translates to:
  /// **'請輸入學號'**
  String get loginUsernamePrompt;

  /// No description provided for @loginPasswordPrompt.
  ///
  /// In zh, this message translates to:
  /// **'請輸入密碼'**
  String get loginPasswordPrompt;

  /// No description provided for @loginCaptchaPrompt.
  ///
  /// In zh, this message translates to:
  /// **'請輸入驗證碼'**
  String get loginCaptchaPrompt;

  /// No description provided for @loginHeading.
  ///
  /// In zh, this message translates to:
  /// **'登入雲科單一入口服務網'**
  String get loginHeading;

  /// No description provided for @loginUsernameLabel.
  ///
  /// In zh, this message translates to:
  /// **'學號'**
  String get loginUsernameLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In zh, this message translates to:
  /// **'密碼'**
  String get loginPasswordLabel;

  /// No description provided for @loginCaptchaLabel.
  ///
  /// In zh, this message translates to:
  /// **'驗證碼'**
  String get loginCaptchaLabel;

  /// No description provided for @loginCaptchaRefreshTooltip.
  ///
  /// In zh, this message translates to:
  /// **'重新整理驗證碼'**
  String get loginCaptchaRefreshTooltip;

  /// No description provided for @loginShowPassword.
  ///
  /// In zh, this message translates to:
  /// **'顯示密碼'**
  String get loginShowPassword;

  /// No description provided for @loginHidePassword.
  ///
  /// In zh, this message translates to:
  /// **'隱藏密碼'**
  String get loginHidePassword;

  /// No description provided for @loginButton.
  ///
  /// In zh, this message translates to:
  /// **'登入'**
  String get loginButton;

  /// No description provided for @loginFailed.
  ///
  /// In zh, this message translates to:
  /// **'帳密或驗證碼錯誤'**
  String get loginFailed;

  /// No description provided for @loginServiceUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'無法連線至單一入口服務網，請稍後再試'**
  String get loginServiceUnavailable;

  /// No description provided for @totpTitle.
  ///
  /// In zh, this message translates to:
  /// **'二步驟驗證'**
  String get totpTitle;

  /// No description provided for @totpPrompt.
  ///
  /// In zh, this message translates to:
  /// **'請輸入驗證器 App（如 Google Authenticator）顯示的 6 位數驗證碼'**
  String get totpPrompt;

  /// No description provided for @totpCodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'驗證碼'**
  String get totpCodeLabel;

  /// No description provided for @totpVerifyButton.
  ///
  /// In zh, this message translates to:
  /// **'驗證'**
  String get totpVerifyButton;

  /// No description provided for @totpCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get totpCancel;

  /// No description provided for @totpFailed.
  ///
  /// In zh, this message translates to:
  /// **'驗證碼錯誤，請重新登入'**
  String get totpFailed;

  /// No description provided for @pleaseLoginToViewSchedule.
  ///
  /// In zh, this message translates to:
  /// **'請在此登入以查看課表'**
  String get pleaseLoginToViewSchedule;

  /// No description provided for @mapModeEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已開啟地圖定位模式，點擊課程直接前往地圖'**
  String get mapModeEnabled;

  /// No description provided for @mapModeDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已關閉地圖定位模式'**
  String get mapModeDisabled;

  /// No description provided for @mapModeTooltip.
  ///
  /// In zh, this message translates to:
  /// **'地圖定位模式'**
  String get mapModeTooltip;

  /// No description provided for @loadScheduleFailed.
  ///
  /// In zh, this message translates to:
  /// **'無法載入課表'**
  String get loadScheduleFailed;

  /// No description provided for @checkNetworkRetry.
  ///
  /// In zh, this message translates to:
  /// **'請確認網路連線後重試'**
  String get checkNetworkRetry;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重試'**
  String get retry;

  /// No description provided for @offlineBanner.
  ///
  /// In zh, this message translates to:
  /// **'離線模式・顯示的是先前的快取資料'**
  String get offlineBanner;

  /// No description provided for @clockSkewBanner.
  ///
  /// In zh, this message translates to:
  /// **'裝置時間誤差過大，可能導致異常，請校正系統時間'**
  String get clockSkewBanner;

  /// No description provided for @loginNoNetwork.
  ///
  /// In zh, this message translates to:
  /// **'無法連線，請檢查網路後再試'**
  String get loginNoNetwork;

  /// No description provided for @noScheduleData.
  ///
  /// In zh, this message translates to:
  /// **'目前沒有任何課表資料'**
  String get noScheduleData;

  /// No description provided for @weekdayHeader.
  ///
  /// In zh, this message translates to:
  /// **'星期{day}'**
  String weekdayHeader(String day);

  /// No description provided for @weekdayMon.
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In zh, this message translates to:
  /// **'五'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In zh, this message translates to:
  /// **'六'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get weekdaySun;

  /// No description provided for @periodHeader.
  ///
  /// In zh, this message translates to:
  /// **'節'**
  String get periodHeader;

  /// No description provided for @periodDetails.
  ///
  /// In zh, this message translates to:
  /// **'第 {period} 節：{time}'**
  String periodDetails(String period, String time);

  /// No description provided for @noClassroomForLocation.
  ///
  /// In zh, this message translates to:
  /// **'此課程無指定教室，無法定位'**
  String get noClassroomForLocation;

  /// No description provided for @classroomLabel.
  ///
  /// In zh, this message translates to:
  /// **'教室: {room}'**
  String classroomLabel(String room);

  /// No description provided for @teacherLabel.
  ///
  /// In zh, this message translates to:
  /// **'教師: {teacher}'**
  String teacherLabel(String teacher);

  /// No description provided for @timeLabel.
  ///
  /// In zh, this message translates to:
  /// **'時段: {time}'**
  String timeLabel(String time);

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'關閉'**
  String get close;

  /// No description provided for @notDecided.
  ///
  /// In zh, this message translates to:
  /// **'未定'**
  String get notDecided;

  /// No description provided for @infoTitle.
  ///
  /// In zh, this message translates to:
  /// **'資訊'**
  String get infoTitle;

  /// No description provided for @infoGradesTitle.
  ///
  /// In zh, this message translates to:
  /// **'成績查詢'**
  String get infoGradesTitle;

  /// No description provided for @infoGradesDesc.
  ///
  /// In zh, this message translates to:
  /// **'查詢學期與歷年成績及班級排名'**
  String get infoGradesDesc;

  /// No description provided for @infoGradTitle.
  ///
  /// In zh, this message translates to:
  /// **'畢業學分'**
  String get infoGradTitle;

  /// No description provided for @infoGradDesc.
  ///
  /// In zh, this message translates to:
  /// **'檢視畢業門檻與修課學分進度'**
  String get infoGradDesc;

  /// No description provided for @infoMapTitle.
  ///
  /// In zh, this message translates to:
  /// **'校園地圖'**
  String get infoMapTitle;

  /// No description provided for @infoMapDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看校園地圖，提供搜尋功能快速查看系館位置'**
  String get infoMapDesc;

  /// No description provided for @infoYunReportTitle.
  ///
  /// In zh, this message translates to:
  /// **'在學證明'**
  String get infoYunReportTitle;

  /// No description provided for @infoYunReportDesc.
  ///
  /// In zh, this message translates to:
  /// **'檢視本學期在學證明'**
  String get infoYunReportDesc;

  /// No description provided for @infoAbsentTitle.
  ///
  /// In zh, this message translates to:
  /// **'請假記錄'**
  String get infoAbsentTitle;

  /// No description provided for @infoAbsentDesc.
  ///
  /// In zh, this message translates to:
  /// **'查詢各學年期的請假申請與簽核狀態'**
  String get infoAbsentDesc;

  /// No description provided for @absentLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'載入請假記錄失敗'**
  String get absentLoadFailed;

  /// No description provided for @absentEmpty.
  ///
  /// In zh, this message translates to:
  /// **'這個學年期沒有請假記錄'**
  String get absentEmpty;

  /// No description provided for @absentHours.
  ///
  /// In zh, this message translates to:
  /// **'請假時數 {hours} 小時'**
  String absentHours(String hours);

  /// No description provided for @infoCommonLinks.
  ///
  /// In zh, this message translates to:
  /// **'常用連結'**
  String get infoCommonLinks;

  /// No description provided for @yunReportUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'無法取得在學證明，請先完成註冊，或稍後再試。'**
  String get yunReportUnavailable;

  /// No description provided for @yunReportRetry.
  ///
  /// In zh, this message translates to:
  /// **'重試'**
  String get yunReportRetry;

  /// No description provided for @yunReportNoteDisplay.
  ///
  /// In zh, this message translates to:
  /// **'僅提供顯示證明使用，如有疑問請洽教務處註冊組。'**
  String get yunReportNoteDisplay;

  /// No description provided for @yunReportNotePaper.
  ///
  /// In zh, this message translates to:
  /// **'如需紙本，請向教務處註冊組提出申請，勿擅自列印。'**
  String get yunReportNotePaper;

  /// No description provided for @loginRememberPassword.
  ///
  /// In zh, this message translates to:
  /// **'記住密碼'**
  String get loginRememberPassword;

  /// No description provided for @loginRememberPasswordHint.
  ///
  /// In zh, this message translates to:
  /// **'供下列功能使用，密碼以雜湊形式儲存於本機中，未勾選不影響其他功能使用。'**
  String get loginRememberPasswordHint;

  /// No description provided for @loginRememberPasswordWarning.
  ///
  /// In zh, this message translates to:
  /// **'如未記住密碼，當憑證失效時，會無法自動登入。'**
  String get loginRememberPasswordWarning;

  /// No description provided for @loginRememberPasswordScope.
  ///
  /// In zh, this message translates to:
  /// **'使用範圍：'**
  String get loginRememberPasswordScope;

  /// No description provided for @appAuthRequiredTitle.
  ///
  /// In zh, this message translates to:
  /// **'需要重新驗證'**
  String get appAuthRequiredTitle;

  /// No description provided for @appAuthRequiredMessage.
  ///
  /// In zh, this message translates to:
  /// **'此功能的授權已過期，請重新輸入密碼以繼續使用。'**
  String get appAuthRequiredMessage;

  /// No description provided for @appAuthUnlock.
  ///
  /// In zh, this message translates to:
  /// **'驗證'**
  String get appAuthUnlock;

  /// No description provided for @appAuthCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get appAuthCancel;

  /// No description provided for @appAuthWrongPassword.
  ///
  /// In zh, this message translates to:
  /// **'密碼錯誤，請重新輸入。'**
  String get appAuthWrongPassword;

  /// No description provided for @changePasswordTitle.
  ///
  /// In zh, this message translates to:
  /// **'變更密碼'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordOldLabel.
  ///
  /// In zh, this message translates to:
  /// **'現在的密碼'**
  String get changePasswordOldLabel;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In zh, this message translates to:
  /// **'新密碼'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordConfirmLabel.
  ///
  /// In zh, this message translates to:
  /// **'確認新密碼'**
  String get changePasswordConfirmLabel;

  /// No description provided for @changePasswordRule.
  ///
  /// In zh, this message translates to:
  /// **'密碼僅可含 A-Z、a-z、0-9 及 @!\$%&*，不得含空白'**
  String get changePasswordRule;

  /// No description provided for @changePasswordHint.
  ///
  /// In zh, this message translates to:
  /// **'修改密碼後，將一併修改 Microsoft 365 與 Google Workspace 之密碼，請記住新密碼。\n使用此處修改密碼後，本應用程式將自動使用新密碼重新登入。'**
  String get changePasswordHint;

  /// No description provided for @changePasswordButton.
  ///
  /// In zh, this message translates to:
  /// **'確認並儲存'**
  String get changePasswordButton;

  /// No description provided for @changePasswordEmpty.
  ///
  /// In zh, this message translates to:
  /// **'請填寫所有欄位'**
  String get changePasswordEmpty;

  /// No description provided for @changePasswordMismatch.
  ///
  /// In zh, this message translates to:
  /// **'兩次輸入的新密碼不一致'**
  String get changePasswordMismatch;

  /// No description provided for @changePasswordInvalidChars.
  ///
  /// In zh, this message translates to:
  /// **'新密碼只能包含 A-Z、a-z、0-9 及 @!\$%&*，且不得含空白'**
  String get changePasswordInvalidChars;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In zh, this message translates to:
  /// **'密碼已變更'**
  String get changePasswordSuccess;

  /// No description provided for @changePasswordFailed.
  ///
  /// In zh, this message translates to:
  /// **'密碼變更失敗，請稍後再試'**
  String get changePasswordFailed;

  /// No description provided for @credentialTitle.
  ///
  /// In zh, this message translates to:
  /// **'應用程式憑證'**
  String get credentialTitle;

  /// No description provided for @credentialStatusTitle.
  ///
  /// In zh, this message translates to:
  /// **'憑證狀態'**
  String get credentialStatusTitle;

  /// No description provided for @credentialStatusValid.
  ///
  /// In zh, this message translates to:
  /// **'有效'**
  String get credentialStatusValid;

  /// No description provided for @credentialStatusNone.
  ///
  /// In zh, this message translates to:
  /// **'尚未取得'**
  String get credentialStatusNone;

  /// No description provided for @credentialExpiryLabel.
  ///
  /// In zh, this message translates to:
  /// **'有效期限：'**
  String get credentialExpiryLabel;

  /// No description provided for @credentialExpiryUnknown.
  ///
  /// In zh, this message translates to:
  /// **'有效期限未知'**
  String get credentialExpiryUnknown;

  /// No description provided for @credentialDaysRemaining.
  ///
  /// In zh, this message translates to:
  /// **'約剩 {days} 天'**
  String credentialDaysRemaining(int days);

  /// No description provided for @credentialEnableRememberTitle.
  ///
  /// In zh, this message translates to:
  /// **'啟用記住密碼'**
  String get credentialEnableRememberTitle;

  /// No description provided for @credentialEnableRememberMessage.
  ///
  /// In zh, this message translates to:
  /// **'請輸入密碼以啟用記住密碼。往後此憑證過期時會自動更新，不需再手動輸入。'**
  String get credentialEnableRememberMessage;

  /// No description provided for @credentialClearOnRestartHint.
  ///
  /// In zh, this message translates to:
  /// **'已取消記住密碼。基於安全考量，本機儲存的密碼將於下次重新啟動應用程式時清除。'**
  String get credentialClearOnRestartHint;

  /// No description provided for @credentialFeaturesTitle.
  ///
  /// In zh, this message translates to:
  /// **'使用此憑證的功能'**
  String get credentialFeaturesTitle;

  /// No description provided for @credentialAbout.
  ///
  /// In zh, this message translates to:
  /// **'部分功能會使用雲科行動 App 的端點，需要一組額外的登入憑證。當憑證過期後若你已記住密碼，App 會自動重新取得憑證；若未記住密碼，使用憑證相關功能時，會請你重新輸入一次密碼。\n密碼僅以雜湊形式儲存於本機安全儲存區，無法還原為明文，也無法用於網頁登入。'**
  String get credentialAbout;

  /// No description provided for @calendarTitle.
  ///
  /// In zh, this message translates to:
  /// **'行事曆'**
  String get calendarTitle;

  /// No description provided for @legendTitle.
  ///
  /// In zh, this message translates to:
  /// **'行事曆圖示說明'**
  String get legendTitle;

  /// No description provided for @legendBgColor.
  ///
  /// In zh, this message translates to:
  /// **'日期背景顏色：'**
  String get legendBgColor;

  /// No description provided for @legendToday.
  ///
  /// In zh, this message translates to:
  /// **'今天日期'**
  String get legendToday;

  /// No description provided for @legendSelected.
  ///
  /// In zh, this message translates to:
  /// **'當前選取日期'**
  String get legendSelected;

  /// No description provided for @legendHoliday.
  ///
  /// In zh, this message translates to:
  /// **'國定假日'**
  String get legendHoliday;

  /// No description provided for @legendVacation.
  ///
  /// In zh, this message translates to:
  /// **'寒假 / 暑假'**
  String get legendVacation;

  /// No description provided for @legendDots.
  ///
  /// In zh, this message translates to:
  /// **'事件小點點：'**
  String get legendDots;

  /// No description provided for @legendEvent.
  ///
  /// In zh, this message translates to:
  /// **'一般事件'**
  String get legendEvent;

  /// No description provided for @legendImportant.
  ///
  /// In zh, this message translates to:
  /// **'重要事件'**
  String get legendImportant;

  /// No description provided for @noEventsToday.
  ///
  /// In zh, this message translates to:
  /// **'本日無行程'**
  String get noEventsToday;

  /// No description provided for @legendTooltip.
  ///
  /// In zh, this message translates to:
  /// **'圖示說明'**
  String get legendTooltip;

  /// No description provided for @backToTodayTooltip.
  ///
  /// In zh, this message translates to:
  /// **'回到今日'**
  String get backToTodayTooltip;

  /// No description provided for @loadCalendarFailed.
  ///
  /// In zh, this message translates to:
  /// **'載入失敗'**
  String get loadCalendarFailed;

  /// No description provided for @loadErrorPrefix.
  ///
  /// In zh, this message translates to:
  /// **'發生錯誤：{error}'**
  String loadErrorPrefix(String error);

  /// No description provided for @gradesTitle.
  ///
  /// In zh, this message translates to:
  /// **'成績查詢'**
  String get gradesTitle;

  /// No description provided for @gradesSegmentSemester.
  ///
  /// In zh, this message translates to:
  /// **'學期'**
  String get gradesSegmentSemester;

  /// No description provided for @gradesSegmentHistory.
  ///
  /// In zh, this message translates to:
  /// **'歷年'**
  String get gradesSegmentHistory;

  /// No description provided for @gradesNoData.
  ///
  /// In zh, this message translates to:
  /// **'尚無成績資料'**
  String get gradesNoData;

  /// No description provided for @gradesNoHistoryData.
  ///
  /// In zh, this message translates to:
  /// **'尚無歷年成績資料'**
  String get gradesNoHistoryData;

  /// No description provided for @gradesNoCurrentData.
  ///
  /// In zh, this message translates to:
  /// **'尚無當前學期的成績資料'**
  String get gradesNoCurrentData;

  /// No description provided for @gradesNotEnrolled.
  ///
  /// In zh, this message translates to:
  /// **'（已畢業或本學期未在學）'**
  String get gradesNotEnrolled;

  /// No description provided for @loadGradesFailed.
  ///
  /// In zh, this message translates to:
  /// **'無法載入成績'**
  String get loadGradesFailed;

  /// No description provided for @pleaseLoginToViewGrades.
  ///
  /// In zh, this message translates to:
  /// **'請在此登入以查看成績'**
  String get pleaseLoginToViewGrades;

  /// No description provided for @gradesAverage.
  ///
  /// In zh, this message translates to:
  /// **'平均成績'**
  String get gradesAverage;

  /// No description provided for @gradesRank.
  ///
  /// In zh, this message translates to:
  /// **'班級排名'**
  String get gradesRank;

  /// No description provided for @gradesEarnedCredits.
  ///
  /// In zh, this message translates to:
  /// **'實得學分'**
  String get gradesEarnedCredits;

  /// No description provided for @gradesGPA.
  ///
  /// In zh, this message translates to:
  /// **'GPA'**
  String get gradesGPA;

  /// No description provided for @gradesGPAShort.
  ///
  /// In zh, this message translates to:
  /// **'GPA: {gpa}'**
  String gradesGPAShort(String gpa);

  /// No description provided for @gradesAverageShort.
  ///
  /// In zh, this message translates to:
  /// **'平均: {avg}'**
  String gradesAverageShort(String avg);

  /// No description provided for @gradesRankShort.
  ///
  /// In zh, this message translates to:
  /// **'排名: {rank}'**
  String gradesRankShort(String rank);

  /// No description provided for @gradesCreditsShort.
  ///
  /// In zh, this message translates to:
  /// **'學分: {credits}'**
  String gradesCreditsShort(String credits);

  /// No description provided for @courseCreditsFormat.
  ///
  /// In zh, this message translates to:
  /// **'{credits} 學分'**
  String courseCreditsFormat(String credits);

  /// No description provided for @gradesSemesterTitle.
  ///
  /// In zh, this message translates to:
  /// **'{year}學年 第{semester}學期'**
  String gradesSemesterTitle(String year, String semester);

  /// No description provided for @courseInstructor.
  ///
  /// In zh, this message translates to:
  /// **'授課教師'**
  String get courseInstructor;

  /// No description provided for @courseContactInfo.
  ///
  /// In zh, this message translates to:
  /// **'聯絡資訊'**
  String get courseContactInfo;

  /// No description provided for @courseCurriculumNo.
  ///
  /// In zh, this message translates to:
  /// **'系所課號'**
  String get courseCurriculumNo;

  /// No description provided for @courseCredits.
  ///
  /// In zh, this message translates to:
  /// **'學分數'**
  String get courseCredits;

  /// No description provided for @courseScheduleClassroom.
  ///
  /// In zh, this message translates to:
  /// **'上課時間教室'**
  String get courseScheduleClassroom;

  /// No description provided for @courseClass.
  ///
  /// In zh, this message translates to:
  /// **'開課班級'**
  String get courseClass;

  /// No description provided for @scheduleNoTimeTitle.
  ///
  /// In zh, this message translates to:
  /// **'無安排上課時間'**
  String get scheduleNoTimeTitle;

  /// No description provided for @courseRequiredElective.
  ///
  /// In zh, this message translates to:
  /// **'修別'**
  String get courseRequiredElective;

  /// No description provided for @courseType.
  ///
  /// In zh, this message translates to:
  /// **'授課方式'**
  String get courseType;

  /// No description provided for @courseRemark.
  ///
  /// In zh, this message translates to:
  /// **'備註'**
  String get courseRemark;

  /// No description provided for @courseGoal.
  ///
  /// In zh, this message translates to:
  /// **'教學目標'**
  String get courseGoal;

  /// No description provided for @courseOutline.
  ///
  /// In zh, this message translates to:
  /// **'課程大綱'**
  String get courseOutline;

  /// No description provided for @courseGrading.
  ///
  /// In zh, this message translates to:
  /// **'成績評量方式'**
  String get courseGrading;

  /// No description provided for @courseSyllabus.
  ///
  /// In zh, this message translates to:
  /// **'教學計畫與進度'**
  String get courseSyllabus;

  /// No description provided for @courseNoData.
  ///
  /// In zh, this message translates to:
  /// **'無資料'**
  String get courseNoData;

  /// No description provided for @courseNone.
  ///
  /// In zh, this message translates to:
  /// **'無'**
  String get courseNone;

  /// No description provided for @courseOpenInBrowser.
  ///
  /// In zh, this message translates to:
  /// **'在瀏覽器開啟'**
  String get courseOpenInBrowser;

  /// No description provided for @courseSelectRoomLocation.
  ///
  /// In zh, this message translates to:
  /// **'選擇上課教室定位'**
  String get courseSelectRoomLocation;

  /// No description provided for @courseGoToRoomLocation.
  ///
  /// In zh, this message translates to:
  /// **'前往 {room} 定位'**
  String courseGoToRoomLocation(String room);

  /// No description provided for @courseInvalidRoomCode.
  ///
  /// In zh, this message translates to:
  /// **'教室代號格式無效，無法定位'**
  String get courseInvalidRoomCode;

  /// No description provided for @courseBuildingNotFound.
  ///
  /// In zh, this message translates to:
  /// **'查無大樓 [{prefix}] 的定位資訊'**
  String courseBuildingNotFound(String prefix);

  /// No description provided for @courseLoadMapDataFailed.
  ///
  /// In zh, this message translates to:
  /// **'讀取地圖資料失敗: {error}'**
  String courseLoadMapDataFailed(String error);

  /// No description provided for @gradLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'無法載入畢業學分'**
  String get gradLoadFailed;

  /// No description provided for @gradNoData.
  ///
  /// In zh, this message translates to:
  /// **'尚無畢業學分資料'**
  String get gradNoData;

  /// No description provided for @gradDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'學分統計詳細'**
  String get gradDetailTitle;

  /// No description provided for @gradTotalNotice.
  ///
  /// In zh, this message translates to:
  /// **'* 合計欄位為通識 + 必修 + 選修'**
  String get gradTotalNotice;

  /// No description provided for @gradMissingRequiredCourses.
  ///
  /// In zh, this message translates to:
  /// **'未修通過必修課'**
  String get gradMissingRequiredCourses;

  /// No description provided for @gradTotalEarnedCredits.
  ///
  /// In zh, this message translates to:
  /// **'總實得學分'**
  String get gradTotalEarnedCredits;

  /// No description provided for @gradEnglishThreshold.
  ///
  /// In zh, this message translates to:
  /// **'英文門檻'**
  String get gradEnglishThreshold;

  /// No description provided for @gradInternshipThreshold.
  ///
  /// In zh, this message translates to:
  /// **'實習門檻'**
  String get gradInternshipThreshold;

  /// No description provided for @gradCategory.
  ///
  /// In zh, this message translates to:
  /// **'類別'**
  String get gradCategory;

  /// No description provided for @gradRequired.
  ///
  /// In zh, this message translates to:
  /// **'應修'**
  String get gradRequired;

  /// No description provided for @gradEarned.
  ///
  /// In zh, this message translates to:
  /// **'實得'**
  String get gradEarned;

  /// No description provided for @gradMissing.
  ///
  /// In zh, this message translates to:
  /// **'尚缺'**
  String get gradMissing;

  /// No description provided for @gradYearFormat.
  ///
  /// In zh, this message translates to:
  /// **'{year}年級'**
  String gradYearFormat(String year);

  /// No description provided for @gradLabelPE.
  ///
  /// In zh, this message translates to:
  /// **'體育'**
  String get gradLabelPE;

  /// No description provided for @gradLabelCivilization.
  ///
  /// In zh, this message translates to:
  /// **'文明'**
  String get gradLabelCivilization;

  /// No description provided for @gradLabelLiterature.
  ///
  /// In zh, this message translates to:
  /// **'文學'**
  String get gradLabelLiterature;

  /// No description provided for @gradLabelGeneral.
  ///
  /// In zh, this message translates to:
  /// **'通識'**
  String get gradLabelGeneral;

  /// No description provided for @gradLabelDeptRequired.
  ///
  /// In zh, this message translates to:
  /// **'必修'**
  String get gradLabelDeptRequired;

  /// No description provided for @gradLabelElective.
  ///
  /// In zh, this message translates to:
  /// **'選修'**
  String get gradLabelElective;

  /// No description provided for @gradLabelTotal.
  ///
  /// In zh, this message translates to:
  /// **'合計'**
  String get gradLabelTotal;

  /// No description provided for @mapLoadingText.
  ///
  /// In zh, this message translates to:
  /// **'正在繪製向量校園地圖...'**
  String get mapLoadingText;

  /// No description provided for @mapSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜尋系館名稱或代號'**
  String get mapSearchHint;

  /// No description provided for @mapQueryRoom.
  ///
  /// In zh, this message translates to:
  /// **'查詢教室：{room}'**
  String mapQueryRoom(String room);

  /// No description provided for @mapNoDescription.
  ///
  /// In zh, this message translates to:
  /// **'暫無此建築物之詳細介紹。'**
  String get mapNoDescription;

  /// No description provided for @mapNavigateButton.
  ///
  /// In zh, this message translates to:
  /// **'導航到這裡'**
  String get mapNavigateButton;

  /// No description provided for @mapNavigateFailed.
  ///
  /// In zh, this message translates to:
  /// **'無法開啟地圖應用程式'**
  String get mapNavigateFailed;

  /// No description provided for @mapResetView.
  ///
  /// In zh, this message translates to:
  /// **'重置地圖檢視'**
  String get mapResetView;

  /// No description provided for @mapFloorPlanUnderConstruction.
  ///
  /// In zh, this message translates to:
  /// **'平面圖建置中'**
  String get mapFloorPlanUnderConstruction;

  /// No description provided for @mapFloorPlanUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'{room} 平面圖不可用'**
  String mapFloorPlanUnavailable(String room);

  /// No description provided for @updateLater.
  ///
  /// In zh, this message translates to:
  /// **'稍後'**
  String get updateLater;

  /// No description provided for @updateReadyTitle.
  ///
  /// In zh, this message translates to:
  /// **'更新已就緒'**
  String get updateReadyTitle;

  /// No description provided for @updateReadyBody.
  ///
  /// In zh, this message translates to:
  /// **'新版本已下載完成，重新啟動即可完成安裝。'**
  String get updateReadyBody;

  /// No description provided for @updateRestart.
  ///
  /// In zh, this message translates to:
  /// **'重新啟動'**
  String get updateRestart;

  /// No description provided for @webViewOpenInBrowser.
  ///
  /// In zh, this message translates to:
  /// **'用外部瀏覽器開啟'**
  String get webViewOpenInBrowser;

  /// No description provided for @webViewCopyLink.
  ///
  /// In zh, this message translates to:
  /// **'複製連結'**
  String get webViewCopyLink;

  /// No description provided for @webViewLinkCopied.
  ///
  /// In zh, this message translates to:
  /// **'已複製連結至剪貼簿'**
  String get webViewLinkCopied;

  /// No description provided for @webViewLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'網頁載入失敗'**
  String get webViewLoadFailed;

  /// No description provided for @webViewRefresh.
  ///
  /// In zh, this message translates to:
  /// **'重新整理'**
  String get webViewRefresh;

  /// No description provided for @profileMinorDoubleMajor.
  ///
  /// In zh, this message translates to:
  /// **'輔系/雙主修'**
  String get profileMinorDoubleMajor;

  /// No description provided for @profileProgram.
  ///
  /// In zh, this message translates to:
  /// **'學程'**
  String get profileProgram;

  /// No description provided for @profileTeacherEducation.
  ///
  /// In zh, this message translates to:
  /// **'教育學程'**
  String get profileTeacherEducation;

  /// No description provided for @settingsGradeNotification.
  ///
  /// In zh, this message translates to:
  /// **'成績更新通知'**
  String get settingsGradeNotification;

  /// No description provided for @settingsGradeNotificationSub.
  ///
  /// In zh, this message translates to:
  /// **'背景每 30 分鐘檢查一次成績'**
  String get settingsGradeNotificationSub;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'無法開啟通知：請前往系統設定啟用通知權限'**
  String get notificationPermissionDenied;

  /// No description provided for @gradeNotifyScoreBody.
  ///
  /// In zh, this message translates to:
  /// **'成績更新：{score} 分'**
  String gradeNotifyScoreBody(String score);

  /// No description provided for @gradeNotifyRankTitle.
  ///
  /// In zh, this message translates to:
  /// **'學期排名'**
  String get gradeNotifyRankTitle;

  /// No description provided for @gradeNotifyRankBody.
  ///
  /// In zh, this message translates to:
  /// **'排名：{rank}'**
  String gradeNotifyRankBody(String rank);

  /// No description provided for @gradeNotifyGpaTitle.
  ///
  /// In zh, this message translates to:
  /// **'學期 GPA'**
  String get gradeNotifyGpaTitle;

  /// No description provided for @gradeNotifyGpaBody.
  ///
  /// In zh, this message translates to:
  /// **'GPA 更新：{gpa}'**
  String gradeNotifyGpaBody(String gpa);

  /// No description provided for @gradeNotifyAvgTitle.
  ///
  /// In zh, this message translates to:
  /// **'學期平均'**
  String get gradeNotifyAvgTitle;

  /// No description provided for @gradeNotifyAvgBody.
  ///
  /// In zh, this message translates to:
  /// **'平均更新：{avg} 分'**
  String gradeNotifyAvgBody(String avg);

  /// No description provided for @termsAgree.
  ///
  /// In zh, this message translates to:
  /// **'同意'**
  String get termsAgree;

  /// No description provided for @termsRejectAndExit.
  ///
  /// In zh, this message translates to:
  /// **'拒絕並退出程式'**
  String get termsRejectAndExit;

  /// No description provided for @termsLastUpdated.
  ///
  /// In zh, this message translates to:
  /// **'最後更新日期：{date}'**
  String termsLastUpdated(String date);

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'重新整理'**
  String get refresh;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
