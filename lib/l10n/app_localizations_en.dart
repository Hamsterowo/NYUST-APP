// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'YunTool';

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
  String get languageSettingSub => 'Change App language in system settings';

  @override
  String get privacyPolicy => 'YunTech Portal Privacy Policy';

  @override
  String get termsOfService => 'YunTool Terms of Service';

  @override
  String get termsUpdateTitle => 'Notice';

  @override
  String get termsUpdateAlert =>
      'The terms of service have been updated. Please agree to them before continuing.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get logout => 'Logout';

  @override
  String get reportIssue => 'Report an Issue';

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
      '※ This page is for reference only and cannot be used as an official proof of enrollment.';

  @override
  String get installError =>
      'Currently unable to install: You might have installed it already, or your browser does not support this feature.';

  @override
  String get featureNotFinished => 'This feature is not finished yet.';

  @override
  String get installTitle => 'Install YunTool APP';

  @override
  String get installDescIos =>
      'Install YunTool shortcut to your device:\n\n1️⃣ Tap the \"Share\" icon at the bottom ⧧\n2️⃣ Scroll down and select \"Add to Home Screen\"\n3️⃣ Tap \"Add\"';

  @override
  String get installDescAndroid =>
      'Install YunTool to your device to run directly without opening a browser.';

  @override
  String get vacationLabelStart => 'Semester Starts';

  @override
  String get vacationLabelWinter => 'Winter Vacation';

  @override
  String get vacationLabelSummer => 'Summer Vacation';

  @override
  String get vacationError => 'Cannot display holiday information';

  @override
  String get vacationCountdownPrefix => 'Still';

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
      'This card displays the countdown to the start of vacation or the new semester.\n\nHow it is calculated:\n1. Early Holiday Start: If vacation start is preceded by consecutive holidays (weekends or national holidays), the start date shifts to the first holiday day.\n2. Countdown & Progress: Shows remaining days to the target date, and the progress bar shows the elapsed percentage.';

  @override
  String get todayClassesTitle => 'Today\'s Classes';

  @override
  String get notLoggedInMessage =>
      'You are not logged in. Please log in first.';

  @override
  String get noClassesToday => 'No classes today!';

  @override
  String get upcomingEventsTitle => 'Upcoming Campus Events';

  @override
  String get noUpcomingEvents => 'No upcoming campus events scheduled.';

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
  String get loginTitle => 'Login to YunTool';

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
  String get loginButton => 'Login';

  @override
  String get loginFailed => 'Invalid username, password, or captcha';

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
  String get retry => 'Retry';

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
  String get infoGradesDesc =>
      'Check semester grades, history, and class rankings.';

  @override
  String get infoGradTitle => 'Graduation Credits';

  @override
  String get infoGradDesc =>
      'Review graduation requirements and credit progress.';

  @override
  String get infoMapTitle => 'Campus Map';

  @override
  String get infoMapDesc =>
      'View the campus map with search functionality to quickly find buildings.';

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
  String loadErrorPrefix(String error) {
    return 'An error occurred: $error';
  }

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
  String get gradesCumulativeAverage => 'Cum. Average';

  @override
  String get gradesCumulativeGPA => 'Cum. GPA';

  @override
  String get gradesCumulativeRank => 'Cum. Rank';

  @override
  String get gradesCumulativeEarnedCredits => 'Cum. Credits';

  @override
  String get gradesCumulativeSummary => 'Cumulative Academic Summary';

  @override
  String gradesGPAShort(String gpa) {
    return 'GPA: $gpa';
  }

  @override
  String get gradesDetailHeader => 'Course Grade Details for This Semester';

  @override
  String get gradesAllDetailHeader => 'Course Grade Details';

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
  String get courseOpenWebpageFailed => 'Failed to open webpage';

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
  String courseLoadMapDataFailed(String error) {
    return 'Failed to load map data: $error';
  }

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
  String get mapExternalNav => 'External Navigation';

  @override
  String get mapFloorPlanUnderConstruction => 'Floor Plan Under Construction';

  @override
  String mapFloorPlanUnavailable(String room) {
    return '$room Floor Plan Unavailable';
  }

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
  String get gradeNotificationTitle => 'Grade Update Notification';

  @override
  String gradeNotificationNewCourse(Object courseName, Object score) {
    return 'New course: $courseName, Grade: $score';
  }

  @override
  String gradeNotificationScoreChanged(
    Object courseName,
    Object newScore,
    Object oldScore,
  ) {
    return '[$courseName] Grade updated: $oldScore -> $newScore';
  }

  @override
  String gradeNotificationRankChanged(Object rank) {
    return 'Semester rank updated to: $rank';
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
  String get termsLoadFailed => 'Failed to load terms of service';

  @override
  String get refresh => 'Refresh';

  @override
  String get reportIssueTitle => 'Report an Issue';

  @override
  String get reportDescriptionPrompt =>
      'Please describe your issue in detail...';

  @override
  String get reportContactPrompt => 'Contact Info (Optional)';

  @override
  String reportEmailOrContactUs(String email) {
    return 'You can also contact us at $email';
  }

  @override
  String reportSubmitSuccess(String caseId) {
    return 'Submitted successfully!\nYour case number is: $caseId';
  }

  @override
  String get reportSend => 'Send';

  @override
  String get reportEmptyDescriptionWarning => 'Please fill in the description';

  @override
  String get reportAddImage => 'Add Image';

  @override
  String get reportRemoveImage => 'Remove Image';

  @override
  String get reportCopiedEmail => 'Copied support email to clipboard';

  @override
  String reportImagePickError(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get reportSubmitError => 'Failed to send, please try again later';

  @override
  String reportSendError(String error) {
    return 'Failed to send: $error';
  }

  @override
  String get errorTimeout => 'Connection timed out, please try again later';

  @override
  String get errorConnection =>
      'Cannot connect to server, please check your network connection';

  @override
  String get errorServer => 'Server responded with an error';

  @override
  String get errorFormat => 'Server response format is invalid';

  @override
  String errorApiCallFailed(String error) {
    return 'API call failed: $error';
  }
}
