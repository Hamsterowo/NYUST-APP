// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get navOverview => 'Overview';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navInfo => 'Info';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navSettings => 'Settings';

  @override
  String get languageSetting => 'Language Settings';

  @override
  String get appPrivacyPolicy => 'YunTool Privacy Policy';

  @override
  String get viewPolicyOnGithub => 'View in Browser';

  @override
  String get termsUpdateTitle => 'Notice';

  @override
  String get termsUpdateAlert =>
      'The privacy policy has been updated. Please agree to it before continuing.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get logout => 'Logout';

  @override
  String get reportIssue => 'Report an Issue';

  @override
  String get reportChannelTitle => 'Choose how to report';

  @override
  String get reportViaEmail => 'Report via Email';

  @override
  String get reportViaDiscord => 'Report via Discord community';

  @override
  String get reportEmailSubject => '[YunTool] Issue Report';

  @override
  String reportEmailBody(String version, String platform) {
    return '[What happened]\n(Describe the problem you ran into)\n\n[Steps you took]\n1. \n2. \n3. \n\n[When it happened]\n\n------ Diagnostic info, please keep ------\nApp version: $version\nPlatform: $platform';
  }

  @override
  String get reportLaunchError => 'Could not open. Please try again.';

  @override
  String get installApp => 'Install APP';

  @override
  String get notPromoted => 'Don\'t show again';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirm';

  @override
  String get install => 'Install';

  @override
  String get profileDisclaimer =>
      '※ This page is for reference only and cannot be used as proof of identity.';

  @override
  String get cancel => 'Cancel';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmMessage =>
      'You\'ll need to sign in again to view your data.';

  @override
  String get profileNameFallback => 'Student';

  @override
  String get profileDepartmentFallback => 'Unknown department';

  @override
  String get profileIdFallback => 'ID unknown';

  @override
  String get profileClassFallback => 'No class info';

  @override
  String get installError =>
      'Currently unable to install: You might have installed it already, or your browser does not support this feature.';

  @override
  String get installTitle => 'Install YunTool APP';

  @override
  String get installDescIos =>
      'Install YunTool shortcut to your device:\n\n1️⃣ Tap the \"Share\" icon at the bottom ⧧\n2️⃣ Scroll down and select \"Add to Home Screen\"\n3️⃣ Tap \"Add\"';

  @override
  String get installDescAndroid =>
      'Install YunTool to your device to run directly without opening a browser.';

  @override
  String get vacationLabelWinter => 'Winter Vacation';

  @override
  String get vacationLabelSummer => 'Summer Vacation';

  @override
  String get vacationError => 'Cannot display holiday information';

  @override
  String get vacationCountdownPrefix => 'Still';

  @override
  String get vacationCountdownPrefixSchool => 'In';

  @override
  String get vacationCountdownSuffix => 'Days';

  @override
  String vacationElapsed(String percentage) {
    return '$percentage% elapsed';
  }

  @override
  String get vacationInfoTitle => 'About Holiday Countdown Card';

  @override
  String get vacationInfoContent =>
      'A countdown to the next break and back to school.\n\n・In session → days until the break\n・On break → days until classes resume\n\nThe bar and bottom percentage show how much of the current phase has elapsed (filling 0→100%).\n\nTip: if a weekend or public holidays fall right before a break, its start shifts to that first day off.';

  @override
  String get todayClassesTitle => 'Today\'s Classes';

  @override
  String get notLoggedInMessage =>
      'You are not logged in. Please log in first.';

  @override
  String get noClassesToday => 'No classes today!';

  @override
  String get todayHolidayNote => 'Day off today';

  @override
  String get upcomingEventsTitle => 'Upcoming Campus Events';

  @override
  String get noUpcomingEvents => 'No upcoming campus events scheduled.';

  @override
  String get eventToday => 'Today';

  @override
  String get eventTomorrow => 'Tomorrow';

  @override
  String eventInDays(int days) {
    return 'In $days days';
  }

  @override
  String get noCourseDetail =>
      'Detailed syllabus is not available for this course.';

  @override
  String get notSpecified => 'No Data';

  @override
  String classPeriods(String periods) {
    return 'Period $periods';
  }

  @override
  String get loginToUseAllFeatures => 'Log in to use all features';

  @override
  String get goToLogin => 'Go to Login';

  @override
  String get loginUsernamePrompt => 'Please enter student ID';

  @override
  String get loginPasswordPrompt => 'Please enter password';

  @override
  String get loginCaptchaPrompt => 'Please enter captcha';

  @override
  String get loginHeading => 'Login to YunTech SSO';

  @override
  String get loginUsernameLabel => 'Student ID';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginCaptchaLabel => 'Captcha';

  @override
  String get loginCaptchaRefreshTooltip => 'Refresh Captcha';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginButton => 'Login';

  @override
  String get loginFailed => 'Invalid username, password, or captcha';

  @override
  String get loginServiceUnavailable =>
      'Cannot reach the YunTech SSO portal. Please try again later.';

  @override
  String get totpTitle => 'Two-Step Verification';

  @override
  String get totpPrompt =>
      'Enter the 6-digit code from your authenticator app\n(e.g. Google Authenticator)';

  @override
  String get totpCodeLabel => 'Verification code';

  @override
  String get totpVerifyButton => 'Verify';

  @override
  String get totpCancel => 'Cancel';

  @override
  String get totpFailed => 'Incorrect code. Please log in again.';

  @override
  String get pleaseLoginToViewSchedule =>
      'Please log in here to view your schedule.';

  @override
  String get mapModeEnabled =>
      'Map positioning mode enabled. Tap a course to view on map.';

  @override
  String get mapModeDisabled => 'Map positioning mode disabled';

  @override
  String get mapModeTooltip => 'Map Mode';

  @override
  String get loadScheduleFailed => 'Failed to load schedule';

  @override
  String get checkNetworkRetry => 'Please check your network and try again.';

  @override
  String serviceUnavailable(String service) {
    return 'Cannot reach $service. Check your network or try again later.';
  }

  @override
  String get serviceGrades => 'the grades system';

  @override
  String get serviceSchedule => 'the schedule system';

  @override
  String get serviceGraduation => 'the graduation audit system';

  @override
  String get serviceAbsent => 'the leave system';

  @override
  String get serviceCalendar => 'the school calendar';

  @override
  String get serviceCourseDetail => 'the course syllabus system';

  @override
  String get serviceYunReport => 'the enrollment certificate service';

  @override
  String get retry => 'Retry';

  @override
  String get offlineBanner => 'Offline — showing previously cached data';

  @override
  String get clockSkewBanner =>
      'Device clock is off — this may cause errors. Please fix your device time.';

  @override
  String get loginNoNetwork =>
      'No internet connection. Please check your network and try again.';

  @override
  String get noScheduleData => 'No schedule data available';

  @override
  String weekdayHeader(String day) {
    return '$day';
  }

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get periodHeader => 'Pd.';

  @override
  String periodDetails(String period, String time) {
    return 'Period $period: $time';
  }

  @override
  String get noClassroomForLocation =>
      'This course has no designated classroom and cannot be located.';

  @override
  String classroomLabel(String room) {
    return 'Classroom: $room';
  }

  @override
  String teacherLabel(String teacher) {
    return 'Teacher: $teacher';
  }

  @override
  String timeLabel(String time) {
    return 'Time: $time';
  }

  @override
  String get close => 'Close';

  @override
  String get notDecided => 'TBD';

  @override
  String get infoTitle => 'Information';

  @override
  String get infoGradesTitle => 'Grades Inquiry';

  @override
  String get infoGradesDesc => 'Semester & past grades, class rankings';

  @override
  String get infoGradTitle => 'Graduation Credits';

  @override
  String get infoGradDesc => 'Graduation requirements & credit progress';

  @override
  String get infoMapTitle => 'Campus Map';

  @override
  String get infoMapDesc => 'Search and locate campus buildings';

  @override
  String get infoYunReportTitle => 'Enrollment Certificate';

  @override
  String get infoYunReportDesc => 'This semester\'s enrollment certificate';

  @override
  String get infoAbsentTitle => 'Leave Records';

  @override
  String get infoAbsentDesc => 'Leave applications & approval status';

  @override
  String get absentLoadFailed => 'Failed to load leave records';

  @override
  String get absentEmpty => 'No leave records for this semester';

  @override
  String absentHours(String hours) {
    return '$hours hour(s)';
  }

  @override
  String get infoCommonLinks => 'Quick Links';

  @override
  String get yunReportUnavailable =>
      'Couldn\'t load the enrollment certificate. Please try again later.';

  @override
  String get yunReportNotRegistered =>
      'The enrollment certificate is unavailable because this semester\'s registration is not complete.';

  @override
  String get yunReportRetry => 'Retry';

  @override
  String get yunReportNoteDisplay =>
      'For on-screen verification only. If you have any questions, please contact the Registration Section of the Office of Academic Affairs.';

  @override
  String get yunReportNotePaper =>
      'For a paper copy, please apply through the Registration Section of the Office of Academic Affairs. Do not print this document yourself.';

  @override
  String get loginRememberPassword => 'Remember password';

  @override
  String get loginRememberPasswordHint =>
      'For the features below. Your password is stored securely on this device. Leaving it off won\'t affect other features.';

  @override
  String get loginRememberPasswordWarning =>
      'If you don\'t remember your password, the app can\'t log in automatically once your credential expires.';

  @override
  String get loginRememberPasswordScope => 'Scope: ';

  @override
  String get appAuthRequiredTitle => 'Re-authentication required';

  @override
  String get appAuthRequiredMessage =>
      'This feature\'s authorization has expired. Please re-enter your password to continue.';

  @override
  String get appAuthUnlock => 'Verify';

  @override
  String get appAuthCancel => 'Cancel';

  @override
  String get appAuthWrongPassword => 'Incorrect password. Please try again.';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get changePasswordOldLabel => 'Current password';

  @override
  String get changePasswordNewLabel => 'New password';

  @override
  String get changePasswordConfirmLabel => 'Confirm new password';

  @override
  String get changePasswordRule =>
      'Password may only contain A-Z, a-z, 0-9 and @!\$%&*, with no spaces.';

  @override
  String get changePasswordHint =>
      'Changing your password also changes your Microsoft 365 and Google Workspace password — please remember the new one.\nAfter you change it here, the app will automatically sign in again with the new password.';

  @override
  String get changePasswordButton => 'Confirm and save';

  @override
  String get changePasswordEmpty => 'Please fill in all fields.';

  @override
  String get changePasswordMismatch => 'The new passwords don\'t match.';

  @override
  String get changePasswordInvalidChars =>
      'New password may only contain A-Z, a-z, 0-9 and @!\$%&*, with no spaces.';

  @override
  String get changePasswordSuccess => 'Password changed.';

  @override
  String get changePasswordFailed =>
      'Couldn\'t change the password. Please try again.';

  @override
  String get credentialTitle => 'App Credential';

  @override
  String get credentialStatusTitle => 'Credential status';

  @override
  String get credentialStatusValid => 'Valid';

  @override
  String get credentialStatusNone => 'Not obtained';

  @override
  String get credentialExpiryLabel => 'Valid until: ';

  @override
  String get credentialExpiryUnknown => 'Expiry unknown';

  @override
  String credentialDaysRemaining(int days) {
    return '~$days days left';
  }

  @override
  String get credentialEnableRememberTitle => 'Enable remember password';

  @override
  String get credentialEnableRememberMessage =>
      'Enter your password to enable remembering it. This credential will then renew automatically when it expires, with no need to re-enter it.';

  @override
  String get credentialClearOnRestartHint =>
      'Remember password turned off. For your security, the password saved on this device will be cleared next time you open the app.';

  @override
  String get credentialFeaturesTitle => 'Features using this credential';

  @override
  String get credentialAbout =>
      'Some features need a separate credential. If you remember your password, the app renews the credential automatically when it expires; otherwise you\'ll be asked to re-enter it when using those features.\nYour password is stored securely on this device only, can\'t be recovered, and can\'t be used for the website login.';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get legendTitle => 'Calendar Icon Legend';

  @override
  String get legendBgColor => 'Date Background Colors:';

  @override
  String get legendToday => 'Today\'s Date';

  @override
  String get legendSelected => 'Selected Date';

  @override
  String get legendHoliday => 'National Holiday';

  @override
  String get legendVacation => 'Winter / Summer Vacation';

  @override
  String get legendDots => 'Event Markers:';

  @override
  String get legendEvent => 'Standard Event';

  @override
  String get legendImportant => 'Important Event';

  @override
  String get noEventsToday => 'No events today';

  @override
  String get legendTooltip => 'Icon Legend';

  @override
  String get backToTodayTooltip => 'Back to Today';

  @override
  String get loadCalendarFailed => 'Failed to load';

  @override
  String get gradesTitle => 'Grades';

  @override
  String get gradesSegmentSemester => 'Semester';

  @override
  String get gradesSegmentHistory => 'History';

  @override
  String get gradesNoData => 'No grades data available';

  @override
  String get gradesNoHistoryData => 'No history grades data available';

  @override
  String get gradesNoCurrentData => 'No grades data for the current semester';

  @override
  String get gradesNotEnrolled => '(Graduated or not enrolled this semester)';

  @override
  String get loadGradesFailed => 'Failed to load grades';

  @override
  String get pleaseLoginToViewGrades => 'Please log in here to view grades.';

  @override
  String get gradesAverage => 'Average Score';

  @override
  String get gradesRank => 'Class Rank';

  @override
  String get gradesEarnedCredits => 'Earned Credits';

  @override
  String get gradesGPA => 'GPA';

  @override
  String gradesGPAShort(String gpa) {
    return 'GPA: $gpa';
  }

  @override
  String gradesAverageShort(String avg) {
    return 'Avg: $avg';
  }

  @override
  String gradesRankShort(String rank) {
    return 'Rank: $rank';
  }

  @override
  String gradesCreditsShort(String credits) {
    return 'Credits: $credits';
  }

  @override
  String courseCreditsFormat(String credits) {
    return '$credits Credits';
  }

  @override
  String gradesSemesterTitle(String year, String semester) {
    return 'Semester $semester, Academic Year $year';
  }

  @override
  String get courseInstructor => 'Instructor';

  @override
  String get courseContactInfo => 'Contact Info';

  @override
  String get courseCurriculumNo => 'Curriculum No.';

  @override
  String get courseCredits => 'Credits';

  @override
  String get courseScheduleClassroom => 'Schedule/Classroom';

  @override
  String get courseClass => 'Class';

  @override
  String get scheduleNoTimeTitle => 'Unscheduled';

  @override
  String get courseRequiredElective => 'Required/Elective';

  @override
  String get courseType => 'Course Type';

  @override
  String get courseRemark => 'Remark';

  @override
  String get courseGoal => 'Teaching Objectives';

  @override
  String get courseOutline => 'Course Outline';

  @override
  String get courseGrading => 'Evaluation Methods';

  @override
  String get courseSyllabus => 'Teaching Plan & Progress';

  @override
  String get courseNoData => 'No Data';

  @override
  String get courseNone => 'None';

  @override
  String get courseOpenInBrowser => 'Open in Browser';

  @override
  String get courseSelectRoomLocation => 'Select Classroom Map Location';

  @override
  String courseGoToRoomLocation(String room) {
    return 'Go to $room Location';
  }

  @override
  String get courseInvalidRoomCode =>
      'Invalid classroom code format, cannot locate';

  @override
  String courseBuildingNotFound(String prefix) {
    return 'No location info found for building [$prefix]';
  }

  @override
  String get courseLoadMapDataFailed => 'Failed to load map data';

  @override
  String get gradLoadFailed => 'Failed to load graduation credits';

  @override
  String get gradNoData => 'No graduation credits data available';

  @override
  String get gradDetailTitle => 'Credit Statistics Details';

  @override
  String get gradTotalNotice =>
      '* The total column is the sum of General Education, Required, and Elective credits';

  @override
  String get gradMissingRequiredCourses => 'Uncompleted Required Courses';

  @override
  String get gradTotalEarnedCredits => 'Total Earned Credits';

  @override
  String get gradEnglishThreshold => 'English Requirement';

  @override
  String get gradInternshipThreshold => 'Internship Requirement';

  @override
  String get gradCategory => 'Category';

  @override
  String get gradRequired => 'Required';

  @override
  String get gradEarned => 'Earned';

  @override
  String get gradMissing => 'Missing';

  @override
  String gradYearFormat(String year) {
    return 'Grade $year';
  }

  @override
  String get gradLabelPE => 'P.E.';

  @override
  String get gradLabelCivilization => 'Civilization';

  @override
  String get gradLabelLiterature => 'Literature';

  @override
  String get gradLabelGeneral => 'General Ed.';

  @override
  String get gradLabelDeptRequired => 'Required';

  @override
  String get gradLabelElective => 'Electives';

  @override
  String get gradLabelTotal => 'Total';

  @override
  String get mapLoadingText => 'Drawing vector campus map...';

  @override
  String get mapSearchHint => 'Search building name or code';

  @override
  String mapQueryRoom(String room) {
    return 'Query classroom: $room';
  }

  @override
  String get mapNoDescription =>
      'No detailed description available for this building.';

  @override
  String get mapNavigateButton => 'Navigate here';

  @override
  String get mapNavigateFailed => 'Couldn\'t open a maps app';

  @override
  String get mapResetView => 'Reset map view';

  @override
  String get mapFloorPlanUnderConstruction => 'Coming Soon';

  @override
  String mapFloorPlanUnavailable(String room) {
    return '$room: No Plan';
  }

  @override
  String get updateLater => 'Later';

  @override
  String get updateReadyTitle => 'Update Ready';

  @override
  String get updateReadyBody =>
      'The new version has been downloaded. Restart to finish installing.';

  @override
  String get updateRestart => 'Restart';

  @override
  String get webViewOpenInBrowser => 'Open in External Browser';

  @override
  String get webViewCopyLink => 'Copy Link';

  @override
  String get webViewLinkCopied => 'Link copied to clipboard';

  @override
  String get webViewLoadFailed => 'Failed to load page';

  @override
  String get webViewRefresh => 'Refresh';

  @override
  String get profileMinorDoubleMajor => 'Minor / Double Major';

  @override
  String get profileProgram => 'Program';

  @override
  String get profileTeacherEducation => 'Teacher Education Program';

  @override
  String get settingsGradeNotification => 'Grade Update Notification';

  @override
  String get settingsGradeNotificationSub =>
      'Check grades in background every 30 mins';

  @override
  String get notificationPermissionDenied =>
      'Cannot enable notifications: Please grant notification permission in system settings';

  @override
  String gradeNotifyScoreBody(String score) {
    return 'Grade updated: $score';
  }

  @override
  String get gradeNotifyRankTitle => 'Semester Rank';

  @override
  String gradeNotifyRankBody(String rank) {
    return 'Rank: $rank';
  }

  @override
  String get gradeNotifyGpaTitle => 'Semester GPA';

  @override
  String gradeNotifyGpaBody(String gpa) {
    return 'GPA updated: $gpa';
  }

  @override
  String get gradeNotifyAvgTitle => 'Semester Average';

  @override
  String gradeNotifyAvgBody(String avg) {
    return 'Average updated: $avg';
  }

  @override
  String get termsAgree => 'Agree';

  @override
  String get termsRejectAndExit => 'Decline & Exit';

  @override
  String termsLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get mapBlockActivityCenter => 'Activity Center';

  @override
  String get mapBlockManagement => 'College of Management';

  @override
  String get mapBlockEngineering => 'College of Engineering';

  @override
  String get mapBlockHumanities => 'College of Humanities';

  @override
  String get mapBlockDesign => 'College of Design';

  @override
  String get mapBlockSportsField => 'Sports Field';

  @override
  String get desktopNoticeTitle => 'YunTool is designed for mobile devices';

  @override
  String get desktopNoticeBody =>
      'You are currently viewing the desktop web version.\n\nFor the best experience, we recommend using a mobile device,\nor tap the button below to continue.';

  @override
  String get desktopContinue => 'Continue';

  @override
  String get devTriggerBgCheckTitle => '[Dev] Trigger a background check now';

  @override
  String get devTriggerBgCheckSubtitle =>
      'Immediately starts one scheduled background task for testing';

  @override
  String get devTriggerBgCheckRegistered =>
      'One-off background task registered — check your notifications!';
}
