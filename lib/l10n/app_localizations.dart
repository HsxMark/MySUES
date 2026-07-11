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

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'苏伊士'**
  String get appTitle;

  /// No description provided for @schedule.
  ///
  /// In zh, this message translates to:
  /// **'课表'**
  String get schedule;

  /// No description provided for @transcript.
  ///
  /// In zh, this message translates to:
  /// **'成绩'**
  String get transcript;

  /// No description provided for @exams.
  ///
  /// In zh, this message translates to:
  /// **'考试'**
  String get exams;

  /// No description provided for @profile.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @general.
  ///
  /// In zh, this message translates to:
  /// **'通用'**
  String get general;

  /// No description provided for @notifications.
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get notifications;

  /// No description provided for @appearanceAndDisplay.
  ///
  /// In zh, this message translates to:
  /// **'界面与显示'**
  String get appearanceAndDisplay;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageSystem;

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @dataAndPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'数据与隐私'**
  String get dataAndPrivacy;

  /// No description provided for @clearAllData.
  ///
  /// In zh, this message translates to:
  /// **'清除所有数据'**
  String get clearAllData;

  /// No description provided for @clearAllDataSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'包括课表、成绩、个人信息及偏好设置'**
  String get clearAllDataSubtitle;

  /// No description provided for @clearAllDataQuestion.
  ///
  /// In zh, this message translates to:
  /// **'清除所有数据？'**
  String get clearAllDataQuestion;

  /// No description provided for @clearAllDataWarning.
  ///
  /// In zh, this message translates to:
  /// **'此操作不可撤销。所有本地存储的课表、成绩、个人设置等都将被永久删除，App 将恢复到初始状态。'**
  String get clearAllDataWarning;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirmClear.
  ///
  /// In zh, this message translates to:
  /// **'确认清除'**
  String get confirmClear;

  /// No description provided for @confirmAgain.
  ///
  /// In zh, this message translates to:
  /// **'再次确认'**
  String get confirmAgain;

  /// No description provided for @confirmClearFinal.
  ///
  /// In zh, this message translates to:
  /// **'真的要删除所有数据吗？数据一旦清除将无法找回。'**
  String get confirmClearFinal;

  /// No description provided for @dataClearedRestart.
  ///
  /// In zh, this message translates to:
  /// **'数据已清除，请重启应用'**
  String get dataClearedRestart;

  /// No description provided for @clearFailed.
  ///
  /// In zh, this message translates to:
  /// **'清除失败：{error}'**
  String clearFailed(String error);

  /// No description provided for @userAgreementAndPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'用户协议与隐私政策'**
  String get userAgreementAndPrivacy;

  /// No description provided for @welcomeAgreement.
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用苏伊士（My SUES）。在使用本应用前，请您仔细阅读并同意以下协议：'**
  String get welcomeAgreement;

  /// No description provided for @userAgreement.
  ///
  /// In zh, this message translates to:
  /// **'用户协议'**
  String get userAgreement;

  /// No description provided for @privacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get privacyPolicy;

  /// No description provided for @agreementFraudWarning.
  ///
  /// In zh, this message translates to:
  /// **'重要提示：本产品为公益性质的完全免费产品，若您是通过付费获取本产品，那您遭遇了诈骗。'**
  String get agreementFraudWarning;

  /// No description provided for @disagreeAndExit.
  ///
  /// In zh, this message translates to:
  /// **'不同意并退出'**
  String get disagreeAndExit;

  /// No description provided for @agreeAndContinue.
  ///
  /// In zh, this message translates to:
  /// **'同意并继续'**
  String get agreeAndContinue;

  /// No description provided for @agreementConsentHint.
  ///
  /// In zh, this message translates to:
  /// **'点击“同意并继续”表示您已阅读并同意以上协议。'**
  String get agreementConsentHint;

  /// No description provided for @legalChinesePrevails.
  ///
  /// In zh, this message translates to:
  /// **'英文译文仅供参考，如有歧义，以中文版本为准。'**
  String get legalChinesePrevails;

  /// No description provided for @defaultSchedule.
  ///
  /// In zh, this message translates to:
  /// **'默认课表'**
  String get defaultSchedule;

  /// No description provided for @scheduleNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未设置课表'**
  String get scheduleNotConfigured;

  /// No description provided for @noCoursesToday.
  ///
  /// In zh, this message translates to:
  /// **'今日无课'**
  String get noCoursesToday;

  /// No description provided for @openAppToUpdateSchedule.
  ///
  /// In zh, this message translates to:
  /// **'请打开 App 更新课表'**
  String get openAppToUpdateSchedule;

  /// No description provided for @enjoyFreeTime.
  ///
  /// In zh, this message translates to:
  /// **'享受美好的空闲时光～'**
  String get enjoyFreeTime;

  /// No description provided for @weekNumber.
  ///
  /// In zh, this message translates to:
  /// **'第 {week} 周'**
  String weekNumber(int week);

  /// No description provided for @weekdayShort.
  ///
  /// In zh, this message translates to:
  /// **'{month}.{day} 周{weekday}'**
  String weekdayShort(int month, int day, String weekday);

  /// No description provided for @mondayShort.
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get mondayShort;

  /// No description provided for @tuesdayShort.
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get tuesdayShort;

  /// No description provided for @wednesdayShort.
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get wednesdayShort;

  /// No description provided for @thursdayShort.
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get thursdayShort;

  /// No description provided for @fridayShort.
  ///
  /// In zh, this message translates to:
  /// **'五'**
  String get fridayShort;

  /// No description provided for @saturdayShort.
  ///
  /// In zh, this message translates to:
  /// **'六'**
  String get saturdayShort;

  /// No description provided for @sundayShort.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get sundayShort;

  /// No description provided for @courseReminder.
  ///
  /// In zh, this message translates to:
  /// **'课程提醒'**
  String get courseReminder;

  /// No description provided for @courseReminderDescription.
  ///
  /// In zh, this message translates to:
  /// **'上课前 15 分钟提醒'**
  String get courseReminderDescription;

  /// No description provided for @classroomLabel.
  ///
  /// In zh, this message translates to:
  /// **'教室'**
  String get classroomLabel;

  /// No description provided for @timeLabel.
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get timeLabel;

  /// No description provided for @locationLabel.
  ///
  /// In zh, this message translates to:
  /// **'地点'**
  String get locationLabel;

  /// No description provided for @courseStartsSoon.
  ///
  /// In zh, this message translates to:
  /// **'{course} 将在 15 分钟后开始{room}'**
  String courseStartsSoon(String course, String room);

  /// No description provided for @examReminder.
  ///
  /// In zh, this message translates to:
  /// **'考试提醒'**
  String get examReminder;

  /// No description provided for @examReminderDescription.
  ///
  /// In zh, this message translates to:
  /// **'考试前 {days} 天提醒'**
  String examReminderDescription(int days);

  /// No description provided for @tomorrow.
  ///
  /// In zh, this message translates to:
  /// **'明天'**
  String get tomorrow;

  /// No description provided for @daysLater.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天后'**
  String daysLater(int days);

  /// No description provided for @examReminderBody.
  ///
  /// In zh, this message translates to:
  /// **'{course} {dayText}考试{time}{location}'**
  String examReminderBody(
    String course,
    String dayText,
    String time,
    String location,
  );

  /// No description provided for @widgetDisplayName.
  ///
  /// In zh, this message translates to:
  /// **'课表小组件'**
  String get widgetDisplayName;

  /// No description provided for @widgetDescription.
  ///
  /// In zh, this message translates to:
  /// **'快速查看今日课表，让你不再错过任何一节课。'**
  String get widgetDescription;
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
