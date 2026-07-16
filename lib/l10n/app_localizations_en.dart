// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My SUES';

  @override
  String get schedule => 'Schedule';

  @override
  String get transcript => 'Grades';

  @override
  String get exams => 'Exams';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get general => 'General';

  @override
  String get notifications => 'Notifications';

  @override
  String get appearanceAndDisplay => 'Appearance & Display';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Follow System';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get dataAndPrivacy => 'Data & Privacy';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get clearAllDataSubtitle =>
      'Includes schedules, grades, profile data, and preferences';

  @override
  String get clearAllDataQuestion => 'Clear all data?';

  @override
  String get clearAllDataWarning =>
      'This cannot be undone. All locally stored schedules, grades, profile data, and settings will be permanently deleted and the app will return to its initial state.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmClear => 'Clear';

  @override
  String get confirmAgain => 'Confirm Again';

  @override
  String get confirmClearFinal =>
      'Do you really want to delete all data? It cannot be recovered after deletion.';

  @override
  String get dataClearedRestart => 'Data cleared. Please restart the app.';

  @override
  String clearFailed(String error) {
    return 'Failed to clear data: $error';
  }

  @override
  String get userAgreementAndPrivacy => 'User Agreement & Privacy Policy';

  @override
  String get welcomeAgreement =>
      'Welcome to My SUES. Before using this app, please read and agree to the following documents:';

  @override
  String get userAgreement => 'User Agreement';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get agreementFraudWarning =>
      'Important: this is a completely free, non-profit app. If you paid to obtain it, you have been scammed.';

  @override
  String get disagreeAndExit => 'Disagree and Exit';

  @override
  String get agreeAndContinue => 'Agree and Continue';

  @override
  String get agreementConsentHint =>
      'By selecting “Agree and Continue,” you confirm that you have read and accepted these documents.';

  @override
  String get legalChinesePrevails =>
      'This English translation is provided for reference. If there is any discrepancy, the Chinese version prevails.';

  @override
  String get defaultSchedule => 'Default Schedule';

  @override
  String get scheduleNotConfigured => 'No Schedule Configured';

  @override
  String get noCoursesToday => 'No Classes Today';

  @override
  String get openAppToUpdateSchedule => 'Open the app to update your schedule';

  @override
  String get enjoyFreeTime => 'Enjoy your free time!';

  @override
  String weekNumber(int week) {
    return 'Week $week';
  }

  @override
  String weekdayShort(int month, int day, String weekday) {
    return '$month.$day $weekday';
  }

  @override
  String get mondayShort => 'Mon';

  @override
  String get tuesdayShort => 'Tue';

  @override
  String get wednesdayShort => 'Wed';

  @override
  String get thursdayShort => 'Thu';

  @override
  String get fridayShort => 'Fri';

  @override
  String get saturdayShort => 'Sat';

  @override
  String get sundayShort => 'Sun';

  @override
  String get courseReminder => 'Class Reminder';

  @override
  String get courseReminderDescription => 'Reminder 15 minutes before class';

  @override
  String get classroomLabel => 'Room';

  @override
  String get timeLabel => 'Time';

  @override
  String get locationLabel => 'Location';

  @override
  String courseStartsSoon(String course, String room) {
    return '$course starts in 15 minutes$room';
  }

  @override
  String get examReminder => 'Exam Reminder';

  @override
  String examReminderDescription(int days) {
    return 'Reminder $days days before an exam';
  }

  @override
  String get tomorrow => 'tomorrow';

  @override
  String daysLater(int days) {
    return 'in $days days';
  }

  @override
  String examReminderBody(
    String course,
    String dayText,
    String time,
    String location,
  ) {
    return '$course exam is $dayText$time$location';
  }

  @override
  String get widgetDisplayName => 'Schedule Widget';

  @override
  String get widgetDescription =>
      'See today\'s classes at a glance and never miss a class.';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get mySuesByHsxMark => 'My SUES by HsxMark';

  @override
  String get mySchedule => 'My Schedule';

  @override
  String get profile2 => 'Profile';

  @override
  String get attendanceExempt => '[Attendance Exempt]';

  @override
  String get retake => '[Retake]';

  @override
  String get outsideThisWeek => '[Outside This Week]';

  @override
  String get fourYearProgram => '(Four-year Program)';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get go => 'Go';

  @override
  String get all => 'All';

  @override
  String get noData => 'No data';

  @override
  String get notSet => 'Not set';

  @override
  String get setValue => 'Set';

  @override
  String get notSelected => 'Not selected';

  @override
  String get unknown => 'Unknown';

  @override
  String get unknownSemester => 'Unknown Semester';

  @override
  String get signIn => 'Sign In';

  @override
  String get academicSystem => 'Academic System';

  @override
  String get signInToYourAccount => 'Sign in to your account';

  @override
  String get signedInUseTheButtonsBelowToRetrieveYour =>
      'Signed in. Use the buttons below to retrieve your data.';

  @override
  String get webVpnDataImport => 'WebVPN Data Import';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get chooseTheDataToRetrieve => 'Choose the data to retrieve';

  @override
  String get chooseASemesterToImport => 'Choose a semester to import';

  @override
  String get importMenu => 'Import Menu';

  @override
  String get retrieveProfile => 'Retrieve Profile';

  @override
  String get retrieveSchedule => 'Retrieve Schedule';

  @override
  String get retrieveGrades => 'Retrieve Grades';

  @override
  String get retrieveExams => 'Retrieve Exams';

  @override
  String get extractionFailedTryAgain => 'Extraction failed. Try again.';

  @override
  String get requestFailedTryAgain => 'Request failed. Try again.';

  @override
  String get failedToRetrieveScheduleData => 'Failed to retrieve schedule data';

  @override
  String get openingTheSchedulePageToRetrieveData =>
      'Opening the schedule page to retrieve data…';

  @override
  String get waitingForThePageToLoad => 'Waiting for the page to load…';

  @override
  String get openingTheAcademicSystem => 'Opening the academic system…';

  @override
  String get openingTheSchedulePage => 'Opening the schedule page…';

  @override
  String get retrievingBasicData => 'Retrieving basic data…';

  @override
  String get retrievingSemesters => 'Retrieving semesters…';

  @override
  String get parsing => 'Parsing…';

  @override
  String get parsingStudentInformation => 'Parsing student information…';

  @override
  String get retrievingProfile => 'Retrieving profile…';

  @override
  String get savingCourseData => 'Saving course data…';

  @override
  String get pageLoadingTimedOutTryAgain =>
      'Page loading timed out. Try again.';

  @override
  String get thePageIsNotReadyTryAgain => 'The page is not ready. Try again.';

  @override
  String get noDataReceivedWaitingToRetry =>
      'No data received. Waiting to retry…';

  @override
  String get noProfileInformationWasFound => 'No profile information was found';

  @override
  String get noExamDataWasFound => 'No exam data was found';

  @override
  String get noExamDataWasFound2 => 'No exam data was found';

  @override
  String get noSemesterListWasFoundTryAgain =>
      'No semester list was found. Try again.';

  @override
  String get noCoursesCouldBeParsed => 'No courses could be parsed';

  @override
  String get noValidProfileInformationCouldBeExtracted =>
      'No valid profile information could be extracted';

  @override
  String get unableToParseTheScheduleData =>
      'Unable to parse the schedule data…';

  @override
  String get unableToRetrieveSemestersTryAgain =>
      'Unable to retrieve semesters. Try again.';

  @override
  String get unableToRetrieveStudentInformationTryAgain =>
      'Unable to retrieve student information. Try again.';

  @override
  String get failedToRetrieveStudentInformation =>
      'Failed to retrieve student information';

  @override
  String get operationCancelled => 'Operation cancelled';

  @override
  String get appearance => 'Appearance';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get systemDefault => 'System Default';

  @override
  String get font => 'Font';

  @override
  String get fontStyle => 'Font Style';

  @override
  String get fontResources => 'Font Resources';

  @override
  String get setBackgroundImage => 'Set Background Image';

  @override
  String get backgroundOpacity => 'Background Opacity';

  @override
  String get splashAnimation => 'Splash Animation';

  @override
  String get showTheSplashAnimationWhenTheAppStarts =>
      'Show the splash animation when the app starts';

  @override
  String get experimentalFeatures => 'Experimental Features';

  @override
  String get experimentalAppearance => 'Experimental Appearance';

  @override
  String get experimentalAppearanceMayReduceContrastOrPerformanceOnSome =>
      'Experimental appearance may reduce contrast or performance on some screens. The default Material You appearance is unaffected.';

  @override
  String get liquidGlassEffectBETA => 'Liquid Glass Effect (BETA)';

  @override
  String get addsAFrostedGlassAppearanceToTheInterface =>
      'Adds a frosted-glass appearance to the interface';

  @override
  String get profile3 => 'Profile';

  @override
  String get nickname => 'Nickname';

  @override
  String get studentID => 'Student ID';

  @override
  String get name => 'Name';

  @override
  String get major => 'Major';

  @override
  String get college => 'College';

  @override
  String get classLabel => 'Class';

  @override
  String get year => 'Year';

  @override
  String get changeNickname => 'Change Nickname';

  @override
  String get changeMajor => 'Change Major';

  @override
  String get changeCollege => 'Change College';

  @override
  String get changeClass => 'Change Class';

  @override
  String get avatar => 'Avatar';

  @override
  String get lastSync => 'Last Sync';

  @override
  String get connectToTheAcademicSystemToSyncYourProfile =>
      'Connect to the academic system to sync your profile';

  @override
  String get academicSync => 'Academic Sync';

  @override
  String get synced => 'Synced';

  @override
  String get notSynced => 'Not Synced';

  @override
  String get tapToSync => 'Tap to Sync';

  @override
  String get signInToTheAcademicSystem => 'Sign in to the Academic System';

  @override
  String get enterMySues => 'Enter My SUES';

  @override
  String get welcomeToMySues => 'Welcome to My SUES';

  @override
  String get yourAllInOneCampusAssistantForASimpler =>
      'Your all-in-one campus assistant for a simpler university life.';

  @override
  String get viewWeeklyOrDailyClassesAndImportSchedulesFrom =>
      'View weekly or daily classes and import schedules from the academic system.';

  @override
  String get reviewGradesAndGpaWheneverYouNeedThem =>
      'Review grades and GPA whenever you need them.';

  @override
  String get keepTrackOfExamTimesAndLocations =>
      'Keep track of exam times and locations.';

  @override
  String get viewSchedule => 'View Schedule';

  @override
  String get viewGrades => 'View Grades';

  @override
  String get viewExams => 'View Exams';

  @override
  String get schedule2 => 'Schedule';

  @override
  String get dailySchedule => 'Daily Schedule';

  @override
  String get scheduleSettings => 'Schedule Settings';

  @override
  String get scheduleDisplay => 'Schedule Display';

  @override
  String get scheduleName => 'Schedule Name';

  @override
  String get newSchedule => 'New Schedule';

  @override
  String get newSchedule2 => 'New Schedule';

  @override
  String get switchSchedule => 'Switch Schedule';

  @override
  String get deleteSchedule => 'Delete Schedule';

  @override
  String get pressAndHoldToDeleteASchedule =>
      'Press and hold to delete a schedule';

  @override
  String get noScheduleFoundCreateOneFirst =>
      'No schedule found. Create one first.';

  @override
  String get syncExam => 'Sync Exam';

  @override
  String get syncSchedule => 'Sync Schedule';

  @override
  String get syncGrades => 'Sync Grades';

  @override
  String get cancelImport => 'Cancel Import';

  @override
  String get importCancelled => 'Import cancelled';

  @override
  String get exportIcs => 'Export ICS';

  @override
  String get exportScheduleIcs => 'Export Schedule (.ics)';

  @override
  String get exportScheduleIcs2 => 'Export Schedule (.ics)';

  @override
  String get thereAreNoCoursesToExport => 'There are no courses to export';

  @override
  String get course => 'Course';

  @override
  String get courseName => 'Course Name';

  @override
  String get instructor => 'Instructor';

  @override
  String get weekday => 'Weekday';

  @override
  String get startWeek => 'Start Week';

  @override
  String get endWeek => 'End Week';

  @override
  String get startPeriod => 'Start Period';

  @override
  String get endPeriod => 'End Period';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get startTimeHHMm => 'Start Time (HH:mm)';

  @override
  String get endTimeHHMm => 'End Time (HH:mm)';

  @override
  String get weekPattern => 'Week Pattern';

  @override
  String get everyWeek => 'Every Week';

  @override
  String get oddWeeks => 'Odd Weeks';

  @override
  String get evenWeeks => 'Even Weeks';

  @override
  String get courseColor => 'Course Color';

  @override
  String get studyStatus => 'Study Status';

  @override
  String get normal => 'Normal';

  @override
  String get retake2 => 'Retake';

  @override
  String get attendanceExempt2 => 'Attendance Exempt';

  @override
  String get editCourse => 'Edit Course';

  @override
  String get addCourse => 'Add Course';

  @override
  String get deleteCourse => 'Delete Course';

  @override
  String get copyCourseName => 'Copy Course Name';

  @override
  String get copyCourseDetailsAsText => 'Copy Course Details as Text';

  @override
  String get courseNameCopied => 'Course name copied';

  @override
  String get courseDetailsCopied => 'Course details copied';

  @override
  String get warningCourseConflict => 'Warning: Course Conflict';

  @override
  String get theFollowingCoursesOverlap => 'The following courses overlap:';

  @override
  String get saveAnywayYouCanViewThemInTheSchedule =>
      'Save anyway? You can view them in the schedule or adjust their study status later.';

  @override
  String get saveAnyway => 'Save Anyway';

  @override
  String get hideThisCourseFromTheSchedule =>
      'Hide this course from the schedule?';

  @override
  String get hiddenCoursesAreNotShownInTheScheduleView =>
      'Hidden courses are not shown in the schedule view';

  @override
  String get grades => 'Grades';

  @override
  String get gpa => 'GPA';

  @override
  String get credits => 'Credits';

  @override
  String get credits2 => 'Credits';

  @override
  String get semesterGpa => 'Semester GPA';

  @override
  String get semester => 'Semester';

  @override
  String get overallGpa => 'Overall GPA';

  @override
  String get courseCredits => 'Course  Credits…';

  @override
  String get pending => 'Pending';

  @override
  String get noGradesYetImportThemFromTheMenu =>
      'No grades yet. Import them from the menu.';

  @override
  String get importTranscript => 'Import Transcript';

  @override
  String get gradeInformation => 'Grade Information';

  @override
  String get clearGrades => 'Clear Grades';

  @override
  String get clear => 'Clear';

  @override
  String get failed => 'Failed';

  @override
  String get deferredExam => 'Deferred';

  @override
  String get examInformation => 'Exam Information';

  @override
  String get examScheduleImported => 'Exam schedule imported';

  @override
  String get addExam => 'Add Exam';

  @override
  String get editExam => 'Edit Exam';

  @override
  String get saveExam => 'Save Exam';

  @override
  String get examInformationMayNotBeCurrentAlwaysConfirmIt =>
      'Exam information may not be current. Always confirm it in the official academic system.';

  @override
  String get noMatchingExams => 'No matching exams';

  @override
  String get clearFinished => 'Clear Finished';

  @override
  String get allFinishedExamsWereCleared => 'All finished exams were cleared';

  @override
  String get examTodayCheckTheTimeCarefully =>
      'Exam today — check the time carefully!';

  @override
  String get copyExamName => 'Copy Exam Name';

  @override
  String get copyExamDetailsAsText => 'Copy Exam Details as Text';

  @override
  String get examNameCopied => 'Exam name copied';

  @override
  String get examDetailsCopied => 'Exam details copied';

  @override
  String get typeLabel => 'Type';

  @override
  String get status => 'Status';

  @override
  String get notStarted => 'Not Started';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get inProgress => 'In Progress';

  @override
  String get finished => 'Finished';

  @override
  String get midterm => 'Midterm';

  @override
  String get finalExam => 'Final';

  @override
  String get makeUpExam => 'Make-up Exam';

  @override
  String get remindMe15MinutesBeforeClass =>
      'Remind me 15 minutes before class';

  @override
  String get notificationPermissionIsRequiredForClassReminders =>
      'Notification permission is required for class reminders';

  @override
  String get notificationPermissionIsRequiredForExamReminders =>
      'Notification permission is required for exam reminders';

  @override
  String get classRemindersEnabled => 'Class reminders enabled';

  @override
  String get classRemindersDisabled => 'Class reminders disabled';

  @override
  String get examRemindersEnabled => 'Exam reminders enabled';

  @override
  String get examRemindersDisabled => 'Exam reminders disabled';

  @override
  String get daysBefore => 'Days Before';

  @override
  String get daysInAdvance => 'Days in Advance';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get chooseReminderTime => 'Choose Reminder Time';

  @override
  String get enableToChooseACustomReminderTime =>
      'Enable to choose a custom reminder time';

  @override
  String get about => 'About';

  @override
  String get projectInformation => 'Project Information';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get checkForUpdates => 'Check for Updates';

  @override
  String get openSource => 'Open Source';

  @override
  String get disclaimer => 'Disclaimer';

  @override
  String get thisFeatureProvidesAConvenientWayToSyncInformation =>
      'This feature provides a convenient way to sync information, but imported data may contain errors. Review the results carefully and rely on the official academic system.';

  @override
  String get doNotShowAgain => 'Do not show again';

  @override
  String get iUnderstand => 'I Understand';

  @override
  String get processing => 'Processing…';

  @override
  String get acknowledgements => 'Acknowledgements';

  @override
  String get sponsors => 'Sponsors';

  @override
  String get author => 'Author';

  @override
  String get independentDeveloper => 'Independent Developer';

  @override
  String get contributionsAndBugReportsAreWelcome =>
      'Contributions and bug reports are welcome';

  @override
  String get homeScreenWidget => 'Home Screen Widget';

  @override
  String get addYourScheduleToTheHomeScreenForQuick =>
      'Add your schedule to the home screen for quick access.';

  @override
  String get degreeProgress => 'Degree Progress';

  @override
  String get semesterProgress => 'Semester Progress';

  @override
  String get timeline => 'Timeline';

  @override
  String get today => 'Today';

  @override
  String get noClassesToday => 'No classes today';

  @override
  String get noUpcomingClasses => 'No upcoming classes';

  @override
  String get upcoming2 => 'Upcoming';

  @override
  String get jumpToAWeekOrDate => 'Jump to a Week or Date';

  @override
  String get goToWeek => 'Go to Week';

  @override
  String get goToASpecificWeek => 'Go to a Specific Week';

  @override
  String get returnToCurrentWeek => 'Return to Current Week';

  @override
  String get switchToDayView => 'Switch to Day View';

  @override
  String get switchToWeekView => 'Switch to Week View';

  @override
  String get weekSettings => 'Week Settings';

  @override
  String get periodsPerDay => 'Periods per Day';

  @override
  String get semesterWeeks => 'Semester Weeks';

  @override
  String get semesterStartDate => 'Semester Start Date';

  @override
  String get showSaturday => 'Show Saturday';

  @override
  String get showSunday => 'Show Sunday';

  @override
  String get showCoursesFromOtherWeeks => 'Show Courses from Other Weeks';

  @override
  String get showCourseTimes => 'Show Course Times';

  @override
  String get showFloatingJumpButton => 'Show Floating Jump Button';

  @override
  String get showHiddenAttendanceExemptCourses =>
      'Show Hidden Attendance-Exempt Courses';

  @override
  String get showHiddenAttendanceExemptCoursesInTheSchedule =>
      'Show hidden attendance-exempt courses in the schedule';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get holidayScheduleAdjustments => 'Holiday Schedule Adjustments';

  @override
  String get scheduleAdjustment => 'Schedule Adjustment';

  @override
  String get moveClassesBetweenDates => 'Move Classes Between Dates';

  @override
  String get chooseSourceDate => 'Choose Source Date';

  @override
  String get chooseTargetDate => 'Choose Target Date';

  @override
  String get dateA => 'Date A';

  @override
  String get dateB => 'Date B';

  @override
  String get confirmAdjustment => 'Confirm Adjustment';

  @override
  String get scheduleAdjustmentCompleted => 'Schedule adjustment completed';

  @override
  String get theDatesMustBeDifferent => 'The dates must be different';

  @override
  String get chooseBothDatesFirst => 'Choose both dates first';

  @override
  String get details => 'Details';

  @override
  String get menu => 'Menu';

  @override
  String get copied => 'Copied';

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String get thisCannotBeUndoneContinue => 'This cannot be undone. Continue?';

  @override
  String get anExamCannotLastLongerThan24Hours =>
      'An exam cannot last longer than 24 hours';

  @override
  String get theEndTimeCannotBeEarlierThanTheStart =>
      'The end time cannot be earlier than the start time';

  @override
  String get scheduleNameCannotBeEmpty => 'Schedule name cannot be empty';

  @override
  String get thatScheduleNameAlreadyExistsChooseAnotherName =>
      'That schedule name already exists. Choose another name.';

  @override
  String get thereMustBeAtLeast10PeriodsPerDay =>
      'There must be at least 10 periods per day';

  @override
  String get aSemesterMustContainAtLeast15Weeks =>
      'A semester must contain at least 15 weeks';

  @override
  String get enterAValidWeekNumber => 'Enter a valid week number';

  @override
  String get enterANickname => 'Enter a nickname';

  @override
  String get enterAMajor => 'Enter a major';

  @override
  String get enterACollege => 'Enter a college';

  @override
  String get enterAClassName => 'Enter a class name';

  @override
  String get enterACourseName => 'Enter a course name';

  @override
  String get enterOrChooseAType => 'Enter or choose a type';

  @override
  String get chooseAStartTime => 'Choose a start time';

  @override
  String get chooseAnEndTime => 'Choose an end time';

  @override
  String get enterBothAStartAndEndTime => 'Enter both a start and end time';

  @override
  String get clearAllGradeDataThisCannotBeUndone =>
      'Clear all grade data? This cannot be undone.';

  @override
  String get pressAndHoldToCopyTheContentBelow =>
      'Press and hold to copy the content below';

  @override
  String get filter => 'Filter: ';

  @override
  String get classTime => 'Class Time';

  @override
  String get sincereThanksToTheFollowingSponsorsListedInNo =>
      'Sincere thanks to the following sponsors, listed in no particular order.';

  @override
  String get forSupportJoinQQGroup1045770691 =>
      'For support, join QQ group 1045770691.';

  @override
  String get engineeringManagementDesign => 'Engineering  Management  Design';

  @override
  String get freeForCommercialUse => 'Free for Commercial Use';

  @override
  String get forInternationalStudents => 'For International Students';

  @override
  String get licensedUnderTheHarmonyOSSansFontLicense =>
      'Licensed under the HarmonyOS Sans Font License';

  @override
  String get licensedUnderTheMiSansFontLicense =>
      'Licensed under the MiSans Font License';

  @override
  String get holidayAdjustmentInstructionsThisMovesClassesFromDateA =>
      'Holiday adjustment instructions:\nThis moves classes from Date A to Date B.\n1. Classes on Date A are moved to Date B.\n2. Existing classes on Date B are cleared.\n3. Only the selected dates are affected; recurring semester arrangements are unchanged.';

  @override
  String get gradeAndGpaCalculationsInThisAppAreFor =>
      'Grade and GPA calculations in this app are for reference only.\n\nUniversity rules and special cases such as unevaluated, repeated, exempted, or deferred courses may differ from these calculations.\n\nAlways rely on the official transcript.';

  @override
  String exportFailedWithError(String error) {
    return 'Export failed: $error';
  }

  @override
  String processingFailedWithError(String error) {
    return 'Processing failed: $error';
  }

  @override
  String extractionFailedWithError(String error) {
    return 'Extraction failed: $error';
  }

  @override
  String genericErrorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String avatarUploadFailedWithError(String error) {
    return 'Failed to upload avatar: $error';
  }

  @override
  String periodNumberWithTime(int period, String time) {
    return 'Period $period $time';
  }

  @override
  String periodRange(int start, int end) {
    return 'Periods $start-$end';
  }

  @override
  String weekRange(int start, int end) {
    return 'Weeks $start-$end';
  }

  @override
  String startsOnDate(String date) {
    return 'Starts: $date';
  }

  @override
  String deleteCourseQuestion(String name) {
    return 'Delete course “$name”?';
  }

  @override
  String deleteItemQuestion(String name) {
    return 'Delete “$name”?';
  }

  @override
  String deleteScheduleQuestion(String name) {
    return 'Delete schedule “$name”?\nAll courses in it will also be deleted.';
  }

  @override
  String weekOutOfRange(int maxWeek) {
    return 'Week out of range. Enter 1-$maxWeek.';
  }

  @override
  String weekInputLabel(int maxWeek) {
    return 'Week (1-$maxWeek)';
  }

  @override
  String providedBy(String provider) {
    return 'Provided by $provider';
  }

  @override
  String importedCourses(int courseCount, int recordCount) {
    String _temp0 = intl.Intl.pluralLogic(
      courseCount,
      locale: localeName,
      other: '$courseCount courses',
      one: '1 course',
    );
    return 'Imported $_temp0 ($recordCount records)';
  }

  @override
  String updatedProfile(String name, String code) {
    return 'Updated: $name$code';
  }

  @override
  String updatedProfileInformation(String name, String studentId) {
    return 'Updated profile: $name$studentId';
  }

  @override
  String parsingSemesterInformation(int count) {
    return 'Parsing semester information ($count)…';
  }

  @override
  String semesterFallbackName(String id) {
    return 'Semester $id';
  }

  @override
  String fetchingSemesterSchedule(String semester) {
    return 'Retrieving the $semester schedule…';
  }

  @override
  String retrievingScoresForSemesters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semesters',
      one: '1 semester',
    );
    return 'Retrieving grades for $_temp0…';
  }

  @override
  String noScoresForSemesters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semesters',
      one: '1 semester',
    );
    return 'No grades found across $_temp0.';
  }

  @override
  String importedScoreRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grade records',
      one: '1 grade record',
    );
    return 'Imported $_temp0.';
  }

  @override
  String retrievingExamsAttempt(int attempt) {
    return 'Retrieving exams… (attempt $attempt)';
  }

  @override
  String daysInAdvanceValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days in advance',
      one: '1 day in advance',
    );
    return '$_temp0';
  }

  @override
  String get retrievingExams => 'Retrieving exams…';

  @override
  String get huaweiSoftwareTechnologies =>
      'Huawei Software Technologies Co., Ltd.';

  @override
  String get xiaomiTechnology => 'Xiaomi Technology Co., Ltd.';

  @override
  String examReminderAt(int days, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Remind $_temp0 before the exam at $time';
  }

  @override
  String examDaysBefore(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days before the exam',
      one: '1 day before the exam',
    );
    return '$_temp0';
  }

  @override
  String lastImportedAt(String time) {
    return 'Last imported $time';
  }

  @override
  String unevaluatedCoursesExcludedFromGpa(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending courses',
      one: '1 pending course',
    );
    return '$_temp0 · excluded from GPA';
  }

  @override
  String creditsValue(String value) {
    return 'Credits: $value';
  }

  @override
  String semesterWeekPosition(String semester, int week, String weekday) {
    return '$semester · Week $week · $weekday';
  }

  @override
  String scheduleEventDate(
    int month,
    int day,
    String weekday,
    String startTime,
    String endTime,
  ) {
    return '$weekday, $month/$day  $startTime-$endTime';
  }

  @override
  String courseScheduleLine(String weekday, String periods, String time) {
    return '$weekday · $periods $time';
  }

  @override
  String examCopyText(String course, String time, String location) {
    return '$course\nTime: $time\nLocation: $location';
  }

  @override
  String get courseDetails => 'Course Details';

  @override
  String get semesterCourseCount => 'Semester Courses';

  @override
  String get semesterTotalCredits => 'Semester Credits';

  @override
  String get courseCode => 'Course Code';

  @override
  String get courseType => 'Course Type';

  @override
  String get assessmentMethod => 'Assessment Method';

  @override
  String get offeringDepartment => 'Offering Department';

  @override
  String get teachingFormat => 'Teaching Format';

  @override
  String get totalClassHours => 'Total Class Hours';

  @override
  String get teachingWeeks => 'Teaching Weeks';

  @override
  String get classHourBreakdown => 'Class Hour Breakdown';

  @override
  String get theoryHours => 'Theory';

  @override
  String get practiceHours => 'Practice';

  @override
  String get focusedPracticeHours => 'Focused Practice';

  @override
  String get dispersedPracticeHours => 'Dispersed Practice';

  @override
  String get assessmentHours => 'Assessment';

  @override
  String get experimentHours => 'Experiment';

  @override
  String get computerHours => 'Computer Lab';

  @override
  String get designHours => 'Design';

  @override
  String get extracurricularHours => 'Extracurricular';

  @override
  String courseCreditValue(String value) {
    return '$value credits';
  }

  @override
  String requiredField(String field) {
    return 'Enter $field';
  }
}
