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
}
