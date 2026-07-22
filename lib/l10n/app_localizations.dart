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
  /// **'三旋翼课程表'**
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
  /// **'欢迎使用三旋翼课程表（My SUES）。在使用本应用前，请您仔细阅读并同意以下协议：'**
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

  /// No description provided for @mon.
  ///
  /// In zh, this message translates to:
  /// **'周一'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In zh, this message translates to:
  /// **'周二'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In zh, this message translates to:
  /// **'周三'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In zh, this message translates to:
  /// **'周四'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In zh, this message translates to:
  /// **'周五'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In zh, this message translates to:
  /// **'周六'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In zh, this message translates to:
  /// **'周日'**
  String get sun;

  /// No description provided for @mySuesByHsxMark.
  ///
  /// In zh, this message translates to:
  /// **'三旋翼课程表 by HsxMark'**
  String get mySuesByHsxMark;

  /// No description provided for @mySchedule.
  ///
  /// In zh, this message translates to:
  /// **'我的课表'**
  String get mySchedule;

  /// No description provided for @profile2.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get profile2;

  /// No description provided for @attendanceExempt.
  ///
  /// In zh, this message translates to:
  /// **'[免听]'**
  String get attendanceExempt;

  /// No description provided for @retake.
  ///
  /// In zh, this message translates to:
  /// **'[重修]'**
  String get retake;

  /// No description provided for @outsideThisWeek.
  ///
  /// In zh, this message translates to:
  /// **'[非本周]'**
  String get outsideThisWeek;

  /// No description provided for @fourYearProgram.
  ///
  /// In zh, this message translates to:
  /// **'(肆年制)'**
  String get fourYearProgram;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get ok;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @skip.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get next;

  /// No description provided for @go.
  ///
  /// In zh, this message translates to:
  /// **'跳转'**
  String get go;

  /// No description provided for @all.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get all;

  /// No description provided for @noData.
  ///
  /// In zh, this message translates to:
  /// **'无数据'**
  String get noData;

  /// No description provided for @notSet.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get notSet;

  /// No description provided for @setValue.
  ///
  /// In zh, this message translates to:
  /// **'已设置'**
  String get setValue;

  /// No description provided for @notSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择'**
  String get notSelected;

  /// No description provided for @unknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get unknown;

  /// No description provided for @unknownSemester.
  ///
  /// In zh, this message translates to:
  /// **'未知学期'**
  String get unknownSemester;

  /// No description provided for @signIn.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get signIn;

  /// No description provided for @academicSystem.
  ///
  /// In zh, this message translates to:
  /// **'教务系统'**
  String get academicSystem;

  /// No description provided for @signInToYourAccount.
  ///
  /// In zh, this message translates to:
  /// **'请登录您的账号'**
  String get signInToYourAccount;

  /// No description provided for @signedInUseTheButtonsBelowToRetrieveYour.
  ///
  /// In zh, this message translates to:
  /// **'登录成功，请点击下方按钮提取数据'**
  String get signedInUseTheButtonsBelowToRetrieveYour;

  /// No description provided for @webVpnDataImport.
  ///
  /// In zh, this message translates to:
  /// **'WebVPN 网页提取'**
  String get webVpnDataImport;

  /// No description provided for @clearCache.
  ///
  /// In zh, this message translates to:
  /// **'清理缓存'**
  String get clearCache;

  /// No description provided for @cacheCleared.
  ///
  /// In zh, this message translates to:
  /// **'缓存已清理'**
  String get cacheCleared;

  /// No description provided for @chooseTheDataToRetrieve.
  ///
  /// In zh, this message translates to:
  /// **'请选择要提取的内容'**
  String get chooseTheDataToRetrieve;

  /// No description provided for @chooseASemesterToImport.
  ///
  /// In zh, this message translates to:
  /// **'请选择导入学期'**
  String get chooseASemesterToImport;

  /// No description provided for @importMenu.
  ///
  /// In zh, this message translates to:
  /// **'提取菜单'**
  String get importMenu;

  /// No description provided for @retrieveProfile.
  ///
  /// In zh, this message translates to:
  /// **'提取个人信息'**
  String get retrieveProfile;

  /// No description provided for @retrieveSchedule.
  ///
  /// In zh, this message translates to:
  /// **'提取课表'**
  String get retrieveSchedule;

  /// No description provided for @retrieveGrades.
  ///
  /// In zh, this message translates to:
  /// **'提取成绩'**
  String get retrieveGrades;

  /// No description provided for @retrieveExams.
  ///
  /// In zh, this message translates to:
  /// **'提取考试安排'**
  String get retrieveExams;

  /// No description provided for @extractionFailedTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'提取失败，请重试'**
  String get extractionFailedTryAgain;

  /// No description provided for @requestFailedTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'抓取失败，请重试'**
  String get requestFailedTryAgain;

  /// No description provided for @failedToRetrieveScheduleData.
  ///
  /// In zh, this message translates to:
  /// **'抓取课表数据失败'**
  String get failedToRetrieveScheduleData;

  /// No description provided for @openingTheSchedulePageToRetrieveData.
  ///
  /// In zh, this message translates to:
  /// **'跳转到课表页面以获取数据...'**
  String get openingTheSchedulePageToRetrieveData;

  /// No description provided for @waitingForThePageToLoad.
  ///
  /// In zh, this message translates to:
  /// **'正在等待页面加载...'**
  String get waitingForThePageToLoad;

  /// No description provided for @openingTheAcademicSystem.
  ///
  /// In zh, this message translates to:
  /// **'正在跳转到教务系统...'**
  String get openingTheAcademicSystem;

  /// No description provided for @openingTheSchedulePage.
  ///
  /// In zh, this message translates to:
  /// **'正在跳转到课表页面...'**
  String get openingTheSchedulePage;

  /// No description provided for @retrievingBasicData.
  ///
  /// In zh, this message translates to:
  /// **'正在获取基础数据...'**
  String get retrievingBasicData;

  /// No description provided for @retrievingSemesters.
  ///
  /// In zh, this message translates to:
  /// **'正在获取学期列表...'**
  String get retrievingSemesters;

  /// No description provided for @parsing.
  ///
  /// In zh, this message translates to:
  /// **'正在解析...'**
  String get parsing;

  /// No description provided for @parsingStudentInformation.
  ///
  /// In zh, this message translates to:
  /// **'正在解析学生信息...'**
  String get parsingStudentInformation;

  /// No description provided for @retrievingProfile.
  ///
  /// In zh, this message translates to:
  /// **'正在提取个人信息...'**
  String get retrievingProfile;

  /// No description provided for @savingCourseData.
  ///
  /// In zh, this message translates to:
  /// **'正在保存课程数据...'**
  String get savingCourseData;

  /// No description provided for @pageLoadingTimedOutTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'页面加载超时，请重试'**
  String get pageLoadingTimedOutTryAgain;

  /// No description provided for @thePageIsNotReadyTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'页面未就绪，请重试'**
  String get thePageIsNotReadyTryAgain;

  /// No description provided for @noDataReceivedWaitingToRetry.
  ///
  /// In zh, this message translates to:
  /// **'未获取到数据，等待重试...'**
  String get noDataReceivedWaitingToRetry;

  /// No description provided for @noProfileInformationWasFound.
  ///
  /// In zh, this message translates to:
  /// **'未检测到个人信息'**
  String get noProfileInformationWasFound;

  /// No description provided for @noExamDataWasFound.
  ///
  /// In zh, this message translates to:
  /// **'未检测到考试数据'**
  String get noExamDataWasFound;

  /// No description provided for @noExamDataWasFound2.
  ///
  /// In zh, this message translates to:
  /// **'未找到考试数据'**
  String get noExamDataWasFound2;

  /// No description provided for @noSemesterListWasFoundTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'未找到学期列表，请重试'**
  String get noSemesterListWasFoundTryAgain;

  /// No description provided for @noCoursesCouldBeParsed.
  ///
  /// In zh, this message translates to:
  /// **'未能解析出任何课程'**
  String get noCoursesCouldBeParsed;

  /// No description provided for @noValidProfileInformationCouldBeExtracted.
  ///
  /// In zh, this message translates to:
  /// **'未能提取到有效的个人信息'**
  String get noValidProfileInformationCouldBeExtracted;

  /// No description provided for @unableToParseTheScheduleData.
  ///
  /// In zh, this message translates to:
  /// **'无法从课表数据中解析...'**
  String get unableToParseTheScheduleData;

  /// No description provided for @unableToRetrieveSemestersTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'无法获取学期列表，请重试'**
  String get unableToRetrieveSemestersTryAgain;

  /// No description provided for @unableToRetrieveStudentInformationTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'无法获取学生信息，请重试'**
  String get unableToRetrieveStudentInformationTryAgain;

  /// No description provided for @failedToRetrieveStudentInformation.
  ///
  /// In zh, this message translates to:
  /// **'获取学生信息失败'**
  String get failedToRetrieveStudentInformation;

  /// No description provided for @operationCancelled.
  ///
  /// In zh, this message translates to:
  /// **'用户取消操作'**
  String get operationCancelled;

  /// No description provided for @appearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearance;

  /// No description provided for @light.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get dark;

  /// No description provided for @lightMode.
  ///
  /// In zh, this message translates to:
  /// **'浅色模式'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get darkMode;

  /// No description provided for @setBackgroundImage.
  ///
  /// In zh, this message translates to:
  /// **'设置背景图片'**
  String get setBackgroundImage;

  /// No description provided for @backgroundOpacity.
  ///
  /// In zh, this message translates to:
  /// **'背景透明度'**
  String get backgroundOpacity;

  /// No description provided for @splashAnimation.
  ///
  /// In zh, this message translates to:
  /// **'开屏动画'**
  String get splashAnimation;

  /// No description provided for @showTheSplashAnimationWhenTheAppStarts.
  ///
  /// In zh, this message translates to:
  /// **'启动应用时显示开屏动画'**
  String get showTheSplashAnimationWhenTheAppStarts;

  /// No description provided for @experimentalFeatures.
  ///
  /// In zh, this message translates to:
  /// **'实验性功能'**
  String get experimentalFeatures;

  /// No description provided for @experimentalAppearance.
  ///
  /// In zh, this message translates to:
  /// **'实验性外观'**
  String get experimentalAppearance;

  /// No description provided for @experimentalAppearanceMayReduceContrastOrPerformanceOnSome.
  ///
  /// In zh, this message translates to:
  /// **'实验性外观可能降低部分页面的对比度或性能，默认 Material You 外观不受影响。'**
  String get experimentalAppearanceMayReduceContrastOrPerformanceOnSome;

  /// No description provided for @liquidGlassEffectBETA.
  ///
  /// In zh, this message translates to:
  /// **'液态玻璃效果 (BETA)'**
  String get liquidGlassEffectBETA;

  /// No description provided for @addsAFrostedGlassAppearanceToTheInterface.
  ///
  /// In zh, this message translates to:
  /// **'开启后界面将呈现磨砂玻璃质感'**
  String get addsAFrostedGlassAppearanceToTheInterface;

  /// No description provided for @profile3.
  ///
  /// In zh, this message translates to:
  /// **'个人资料'**
  String get profile3;

  /// No description provided for @nickname.
  ///
  /// In zh, this message translates to:
  /// **'昵称'**
  String get nickname;

  /// No description provided for @studentID.
  ///
  /// In zh, this message translates to:
  /// **'学号'**
  String get studentID;

  /// No description provided for @name.
  ///
  /// In zh, this message translates to:
  /// **'姓名'**
  String get name;

  /// No description provided for @major.
  ///
  /// In zh, this message translates to:
  /// **'专业'**
  String get major;

  /// No description provided for @college.
  ///
  /// In zh, this message translates to:
  /// **'学院'**
  String get college;

  /// No description provided for @classLabel.
  ///
  /// In zh, this message translates to:
  /// **'班级'**
  String get classLabel;

  /// No description provided for @year.
  ///
  /// In zh, this message translates to:
  /// **'年级'**
  String get year;

  /// No description provided for @changeNickname.
  ///
  /// In zh, this message translates to:
  /// **'修改昵称'**
  String get changeNickname;

  /// No description provided for @changeMajor.
  ///
  /// In zh, this message translates to:
  /// **'修改专业'**
  String get changeMajor;

  /// No description provided for @changeCollege.
  ///
  /// In zh, this message translates to:
  /// **'修改学院'**
  String get changeCollege;

  /// No description provided for @changeClass.
  ///
  /// In zh, this message translates to:
  /// **'修改班级'**
  String get changeClass;

  /// No description provided for @avatar.
  ///
  /// In zh, this message translates to:
  /// **'头像'**
  String get avatar;

  /// No description provided for @lastSync.
  ///
  /// In zh, this message translates to:
  /// **'上次同步时间'**
  String get lastSync;

  /// No description provided for @connectToTheAcademicSystemToSyncYourProfile.
  ///
  /// In zh, this message translates to:
  /// **'请连接教务系统同步身份信息'**
  String get connectToTheAcademicSystemToSyncYourProfile;

  /// No description provided for @academicSync.
  ///
  /// In zh, this message translates to:
  /// **'教务同步'**
  String get academicSync;

  /// No description provided for @synced.
  ///
  /// In zh, this message translates to:
  /// **'已同步'**
  String get synced;

  /// No description provided for @notSynced.
  ///
  /// In zh, this message translates to:
  /// **'未同步'**
  String get notSynced;

  /// No description provided for @tapToSync.
  ///
  /// In zh, this message translates to:
  /// **'点击开始同步'**
  String get tapToSync;

  /// No description provided for @signInToTheAcademicSystem.
  ///
  /// In zh, this message translates to:
  /// **'请登录 教务系统'**
  String get signInToTheAcademicSystem;

  /// No description provided for @enterMySues.
  ///
  /// In zh, this message translates to:
  /// **'进入 三旋翼课程表'**
  String get enterMySues;

  /// No description provided for @welcomeToMySues.
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用三旋翼课程表 My SUES'**
  String get welcomeToMySues;

  /// No description provided for @yourAllInOneCampusAssistantForASimpler.
  ///
  /// In zh, this message translates to:
  /// **'一站式校园信息助手，让你的校园生活更便捷。'**
  String get yourAllInOneCampusAssistantForASimpler;

  /// No description provided for @viewWeeklyOrDailyClassesAndImportSchedulesFrom.
  ///
  /// In zh, this message translates to:
  /// **'快速查看每周或每日课程安排，支持导入教务系统课表。'**
  String get viewWeeklyOrDailyClassesAndImportSchedulesFrom;

  /// No description provided for @reviewGradesAndGpaWheneverYouNeedThem.
  ///
  /// In zh, this message translates to:
  /// **'随时查看各科成绩与绩点，掌握学业情况。'**
  String get reviewGradesAndGpaWheneverYouNeedThem;

  /// No description provided for @keepTrackOfExamTimesAndLocations.
  ///
  /// In zh, this message translates to:
  /// **'及时获取考试时间与地点，不错过每场考试。'**
  String get keepTrackOfExamTimesAndLocations;

  /// No description provided for @viewSchedule.
  ///
  /// In zh, this message translates to:
  /// **'查看课表'**
  String get viewSchedule;

  /// No description provided for @viewGrades.
  ///
  /// In zh, this message translates to:
  /// **'查看个人成绩'**
  String get viewGrades;

  /// No description provided for @viewExams.
  ///
  /// In zh, this message translates to:
  /// **'查看考试信息'**
  String get viewExams;

  /// No description provided for @schedule2.
  ///
  /// In zh, this message translates to:
  /// **'课程表'**
  String get schedule2;

  /// No description provided for @dailySchedule.
  ///
  /// In zh, this message translates to:
  /// **'每日课表'**
  String get dailySchedule;

  /// No description provided for @scheduleSettings.
  ///
  /// In zh, this message translates to:
  /// **'课表设置'**
  String get scheduleSettings;

  /// No description provided for @scheduleDisplay.
  ///
  /// In zh, this message translates to:
  /// **'课表显示设置'**
  String get scheduleDisplay;

  /// No description provided for @scheduleName.
  ///
  /// In zh, this message translates to:
  /// **'课表名称'**
  String get scheduleName;

  /// No description provided for @newSchedule.
  ///
  /// In zh, this message translates to:
  /// **'新课表'**
  String get newSchedule;

  /// No description provided for @newSchedule2.
  ///
  /// In zh, this message translates to:
  /// **'新建课表'**
  String get newSchedule2;

  /// No description provided for @switchSchedule.
  ///
  /// In zh, this message translates to:
  /// **'切换课表'**
  String get switchSchedule;

  /// No description provided for @deleteSchedule.
  ///
  /// In zh, this message translates to:
  /// **'删除课表'**
  String get deleteSchedule;

  /// No description provided for @pressAndHoldToDeleteASchedule.
  ///
  /// In zh, this message translates to:
  /// **'长按删除课表'**
  String get pressAndHoldToDeleteASchedule;

  /// No description provided for @noScheduleFoundCreateOneFirst.
  ///
  /// In zh, this message translates to:
  /// **'没有课表数据，请先创建课表'**
  String get noScheduleFoundCreateOneFirst;

  /// No description provided for @syncExam.
  ///
  /// In zh, this message translates to:
  /// **'同步考试'**
  String get syncExam;

  /// No description provided for @syncSchedule.
  ///
  /// In zh, this message translates to:
  /// **'同步课表'**
  String get syncSchedule;

  /// No description provided for @syncGrades.
  ///
  /// In zh, this message translates to:
  /// **'同步成绩'**
  String get syncGrades;

  /// No description provided for @cancelImport.
  ///
  /// In zh, this message translates to:
  /// **'取消导入'**
  String get cancelImport;

  /// No description provided for @importCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消导入'**
  String get importCancelled;

  /// No description provided for @exportIcs.
  ///
  /// In zh, this message translates to:
  /// **'导出 ICS'**
  String get exportIcs;

  /// No description provided for @exportScheduleIcs.
  ///
  /// In zh, this message translates to:
  /// **'导出课表 (.ics)'**
  String get exportScheduleIcs;

  /// No description provided for @exportScheduleIcs2.
  ///
  /// In zh, this message translates to:
  /// **'导出课表(.ics)'**
  String get exportScheduleIcs2;

  /// No description provided for @thereAreNoCoursesToExport.
  ///
  /// In zh, this message translates to:
  /// **'当前没有课程可以导出'**
  String get thereAreNoCoursesToExport;

  /// No description provided for @course.
  ///
  /// In zh, this message translates to:
  /// **'课程'**
  String get course;

  /// No description provided for @courseName.
  ///
  /// In zh, this message translates to:
  /// **'课程名称'**
  String get courseName;

  /// No description provided for @instructor.
  ///
  /// In zh, this message translates to:
  /// **'老师'**
  String get instructor;

  /// No description provided for @weekday.
  ///
  /// In zh, this message translates to:
  /// **'星期'**
  String get weekday;

  /// No description provided for @startWeek.
  ///
  /// In zh, this message translates to:
  /// **'开始周'**
  String get startWeek;

  /// No description provided for @endWeek.
  ///
  /// In zh, this message translates to:
  /// **'结束周'**
  String get endWeek;

  /// No description provided for @startPeriod.
  ///
  /// In zh, this message translates to:
  /// **'开始节次'**
  String get startPeriod;

  /// No description provided for @endPeriod.
  ///
  /// In zh, this message translates to:
  /// **'结束节次'**
  String get endPeriod;

  /// No description provided for @startTime.
  ///
  /// In zh, this message translates to:
  /// **'开始时间'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In zh, this message translates to:
  /// **'结束时间'**
  String get endTime;

  /// No description provided for @startTimeHHMm.
  ///
  /// In zh, this message translates to:
  /// **'开始时间(HH:mm)'**
  String get startTimeHHMm;

  /// No description provided for @endTimeHHMm.
  ///
  /// In zh, this message translates to:
  /// **'结束时间(HH:mm)'**
  String get endTimeHHMm;

  /// No description provided for @weekPattern.
  ///
  /// In zh, this message translates to:
  /// **'单双周'**
  String get weekPattern;

  /// No description provided for @everyWeek.
  ///
  /// In zh, this message translates to:
  /// **'每周'**
  String get everyWeek;

  /// No description provided for @oddWeeks.
  ///
  /// In zh, this message translates to:
  /// **'单周'**
  String get oddWeeks;

  /// No description provided for @evenWeeks.
  ///
  /// In zh, this message translates to:
  /// **'双周'**
  String get evenWeeks;

  /// No description provided for @courseColor.
  ///
  /// In zh, this message translates to:
  /// **'课程颜色'**
  String get courseColor;

  /// No description provided for @studyStatus.
  ///
  /// In zh, this message translates to:
  /// **'修读状态'**
  String get studyStatus;

  /// No description provided for @normal.
  ///
  /// In zh, this message translates to:
  /// **'正常修读'**
  String get normal;

  /// No description provided for @retake2.
  ///
  /// In zh, this message translates to:
  /// **'重修'**
  String get retake2;

  /// No description provided for @attendanceExempt2.
  ///
  /// In zh, this message translates to:
  /// **'免听'**
  String get attendanceExempt2;

  /// No description provided for @editCourse.
  ///
  /// In zh, this message translates to:
  /// **'编辑课程'**
  String get editCourse;

  /// No description provided for @addCourse.
  ///
  /// In zh, this message translates to:
  /// **'添加课程'**
  String get addCourse;

  /// No description provided for @deleteCourse.
  ///
  /// In zh, this message translates to:
  /// **'删除课程'**
  String get deleteCourse;

  /// No description provided for @copyCourseName.
  ///
  /// In zh, this message translates to:
  /// **'复制课程名称'**
  String get copyCourseName;

  /// No description provided for @copyCourseDetailsAsText.
  ///
  /// In zh, this message translates to:
  /// **'复制课程信息为文本'**
  String get copyCourseDetailsAsText;

  /// No description provided for @courseNameCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制课程名称'**
  String get courseNameCopied;

  /// No description provided for @courseDetailsCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制课程信息'**
  String get courseDetailsCopied;

  /// No description provided for @warningCourseConflict.
  ///
  /// In zh, this message translates to:
  /// **'注意：存在课程冲突'**
  String get warningCourseConflict;

  /// No description provided for @theFollowingCoursesOverlap.
  ///
  /// In zh, this message translates to:
  /// **'您有以下课程在同一时间段产生冲突：'**
  String get theFollowingCoursesOverlap;

  /// No description provided for @saveAnywayYouCanViewThemInTheSchedule.
  ///
  /// In zh, this message translates to:
  /// **'是否继续保存？您可以在课表中正常查看它们，或后续修改免听/重修状态。'**
  String get saveAnywayYouCanViewThemInTheSchedule;

  /// No description provided for @saveAnyway.
  ///
  /// In zh, this message translates to:
  /// **'继续保存'**
  String get saveAnyway;

  /// No description provided for @hideThisCourseFromTheSchedule.
  ///
  /// In zh, this message translates to:
  /// **'是否在课表中隐藏？'**
  String get hideThisCourseFromTheSchedule;

  /// No description provided for @hiddenCoursesAreNotShownInTheScheduleView.
  ///
  /// In zh, this message translates to:
  /// **'隐藏后将不会在课表视图中显示该课程'**
  String get hiddenCoursesAreNotShownInTheScheduleView;

  /// No description provided for @grades.
  ///
  /// In zh, this message translates to:
  /// **'成绩单'**
  String get grades;

  /// No description provided for @gpa.
  ///
  /// In zh, this message translates to:
  /// **'绩点'**
  String get gpa;

  /// No description provided for @credits.
  ///
  /// In zh, this message translates to:
  /// **'学分'**
  String get credits;

  /// No description provided for @credits2.
  ///
  /// In zh, this message translates to:
  /// **'修读学分'**
  String get credits2;

  /// No description provided for @semesterGpa.
  ///
  /// In zh, this message translates to:
  /// **'学期 GPA'**
  String get semesterGpa;

  /// No description provided for @semester.
  ///
  /// In zh, this message translates to:
  /// **'学期详情'**
  String get semester;

  /// No description provided for @overallGpa.
  ///
  /// In zh, this message translates to:
  /// **'总平均绩点 (GPA)'**
  String get overallGpa;

  /// No description provided for @courseCredits.
  ///
  /// In zh, this message translates to:
  /// **'课程 学分...'**
  String get courseCredits;

  /// No description provided for @pending.
  ///
  /// In zh, this message translates to:
  /// **'未评教'**
  String get pending;

  /// No description provided for @noGradesYetImportThemFromTheMenu.
  ///
  /// In zh, this message translates to:
  /// **'暂无成绩数据，点击右上方按钮进行导入'**
  String get noGradesYetImportThemFromTheMenu;

  /// No description provided for @importTranscript.
  ///
  /// In zh, this message translates to:
  /// **'导入成绩单'**
  String get importTranscript;

  /// No description provided for @gradeInformation.
  ///
  /// In zh, this message translates to:
  /// **'成绩说明'**
  String get gradeInformation;

  /// No description provided for @clearGrades.
  ///
  /// In zh, this message translates to:
  /// **'清空成绩'**
  String get clearGrades;

  /// No description provided for @clear.
  ///
  /// In zh, this message translates to:
  /// **'确认清空'**
  String get clear;

  /// No description provided for @failed.
  ///
  /// In zh, this message translates to:
  /// **'挂科'**
  String get failed;

  /// No description provided for @deferredExam.
  ///
  /// In zh, this message translates to:
  /// **'缓考'**
  String get deferredExam;

  /// No description provided for @examInformation.
  ///
  /// In zh, this message translates to:
  /// **'考试信息'**
  String get examInformation;

  /// No description provided for @examScheduleImported.
  ///
  /// In zh, this message translates to:
  /// **'考试安排导入成功'**
  String get examScheduleImported;

  /// No description provided for @addExam.
  ///
  /// In zh, this message translates to:
  /// **'添加考试'**
  String get addExam;

  /// No description provided for @editExam.
  ///
  /// In zh, this message translates to:
  /// **'编辑考试'**
  String get editExam;

  /// No description provided for @saveExam.
  ///
  /// In zh, this message translates to:
  /// **'保存考试信息'**
  String get saveExam;

  /// No description provided for @examInformationMayNotBeCurrentAlwaysConfirmIt.
  ///
  /// In zh, this message translates to:
  /// **'考试信息非即时获取，仅供参考，请以教务处系统提示为准！'**
  String get examInformationMayNotBeCurrentAlwaysConfirmIt;

  /// No description provided for @noMatchingExams.
  ///
  /// In zh, this message translates to:
  /// **'暂无符合条件的考试信息'**
  String get noMatchingExams;

  /// No description provided for @clearFinished.
  ///
  /// In zh, this message translates to:
  /// **'清除已结束'**
  String get clearFinished;

  /// No description provided for @allFinishedExamsWereCleared.
  ///
  /// In zh, this message translates to:
  /// **'已清除所有已结束的考试'**
  String get allFinishedExamsWereCleared;

  /// No description provided for @examTodayCheckTheTimeCarefully.
  ///
  /// In zh, this message translates to:
  /// **'今日考试，请注意时间！'**
  String get examTodayCheckTheTimeCarefully;

  /// No description provided for @copyExamName.
  ///
  /// In zh, this message translates to:
  /// **'复制考试名称'**
  String get copyExamName;

  /// No description provided for @copyExamDetailsAsText.
  ///
  /// In zh, this message translates to:
  /// **'复制考试信息为文本'**
  String get copyExamDetailsAsText;

  /// No description provided for @examNameCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制考试名称'**
  String get examNameCopied;

  /// No description provided for @examDetailsCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制考试信息'**
  String get examDetailsCopied;

  /// No description provided for @typeLabel.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get typeLabel;

  /// No description provided for @status.
  ///
  /// In zh, this message translates to:
  /// **'当前状态'**
  String get status;

  /// No description provided for @notStarted.
  ///
  /// In zh, this message translates to:
  /// **'未开始'**
  String get notStarted;

  /// No description provided for @upcoming.
  ///
  /// In zh, this message translates to:
  /// **'未结束'**
  String get upcoming;

  /// No description provided for @inProgress.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get inProgress;

  /// No description provided for @finished.
  ///
  /// In zh, this message translates to:
  /// **'已结束'**
  String get finished;

  /// No description provided for @midterm.
  ///
  /// In zh, this message translates to:
  /// **'期中'**
  String get midterm;

  /// No description provided for @finalExam.
  ///
  /// In zh, this message translates to:
  /// **'期末'**
  String get finalExam;

  /// No description provided for @makeUpExam.
  ///
  /// In zh, this message translates to:
  /// **'补考'**
  String get makeUpExam;

  /// No description provided for @remindMe15MinutesBeforeClass.
  ///
  /// In zh, this message translates to:
  /// **'上课前15分钟提醒'**
  String get remindMe15MinutesBeforeClass;

  /// No description provided for @notificationPermissionIsRequiredForClassReminders.
  ///
  /// In zh, this message translates to:
  /// **'需要通知权限才能设置课程提醒'**
  String get notificationPermissionIsRequiredForClassReminders;

  /// No description provided for @notificationPermissionIsRequiredForExamReminders.
  ///
  /// In zh, this message translates to:
  /// **'需要通知权限才能设置考试提醒'**
  String get notificationPermissionIsRequiredForExamReminders;

  /// No description provided for @classRemindersEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已开启课程提醒'**
  String get classRemindersEnabled;

  /// No description provided for @classRemindersDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已关闭课程提醒'**
  String get classRemindersDisabled;

  /// No description provided for @examRemindersEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已开启考试提醒'**
  String get examRemindersEnabled;

  /// No description provided for @examRemindersDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已关闭考试提醒'**
  String get examRemindersDisabled;

  /// No description provided for @daysBefore.
  ///
  /// In zh, this message translates to:
  /// **'提前几天提醒'**
  String get daysBefore;

  /// No description provided for @daysInAdvance.
  ///
  /// In zh, this message translates to:
  /// **'提前天数'**
  String get daysInAdvance;

  /// No description provided for @reminderTime.
  ///
  /// In zh, this message translates to:
  /// **'提醒时间'**
  String get reminderTime;

  /// No description provided for @chooseReminderTime.
  ///
  /// In zh, this message translates to:
  /// **'选择提醒时间'**
  String get chooseReminderTime;

  /// No description provided for @enableToChooseACustomReminderTime.
  ///
  /// In zh, this message translates to:
  /// **'开启后可自定义提醒时间'**
  String get enableToChooseACustomReminderTime;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @projectInformation.
  ///
  /// In zh, this message translates to:
  /// **'项目信息'**
  String get projectInformation;

  /// No description provided for @tutorial.
  ///
  /// In zh, this message translates to:
  /// **'软件介绍'**
  String get tutorial;

  /// No description provided for @checkForUpdates.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get checkForUpdates;

  /// No description provided for @openSource.
  ///
  /// In zh, this message translates to:
  /// **'开源信息'**
  String get openSource;

  /// No description provided for @disclaimer.
  ///
  /// In zh, this message translates to:
  /// **'免责声明'**
  String get disclaimer;

  /// No description provided for @thisFeatureProvidesAConvenientWayToSyncInformation.
  ///
  /// In zh, this message translates to:
  /// **'本功能仅提供便捷的信息同步服务，导入的数据可能存在偏差。请仔细核对同步后的信息，一切以教务处网站显示为准。'**
  String get thisFeatureProvidesAConvenientWayToSyncInformation;

  /// No description provided for @doNotShowAgain.
  ///
  /// In zh, this message translates to:
  /// **'不再显示'**
  String get doNotShowAgain;

  /// No description provided for @appIntegrityWarningTitle.
  ///
  /// In zh, this message translates to:
  /// **'应用来源提醒'**
  String get appIntegrityWarningTitle;

  /// No description provided for @appIntegrityWarningMessage.
  ///
  /// In zh, this message translates to:
  /// **'无法确认此应用是否来自官方。它可能已被第三方修改，存在账号、数据或设备安全风险。'**
  String get appIntegrityWarningMessage;

  /// No description provided for @appIntegrityRiskAcknowledgement.
  ///
  /// In zh, this message translates to:
  /// **'继续使用即表示您已了解并自行承担相关风险与损失。'**
  String get appIntegrityRiskAcknowledgement;

  /// No description provided for @downloadOfficialVersion.
  ///
  /// In zh, this message translates to:
  /// **'查看官方网站'**
  String get downloadOfficialVersion;

  /// No description provided for @continueUsing.
  ///
  /// In zh, this message translates to:
  /// **'继续使用'**
  String get continueUsing;

  /// No description provided for @officialDownloadOpenFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法打开官方网站，请稍后重试。'**
  String get officialDownloadOpenFailed;

  /// No description provided for @doNotRemindAtStartup.
  ///
  /// In zh, this message translates to:
  /// **'不再弹出'**
  String get doNotRemindAtStartup;

  /// No description provided for @iUnderstand.
  ///
  /// In zh, this message translates to:
  /// **'我已知悉'**
  String get iUnderstand;

  /// No description provided for @processing.
  ///
  /// In zh, this message translates to:
  /// **'处理中...'**
  String get processing;

  /// No description provided for @acknowledgements.
  ///
  /// In zh, this message translates to:
  /// **'鸣谢'**
  String get acknowledgements;

  /// No description provided for @sponsors.
  ///
  /// In zh, this message translates to:
  /// **'赞助者'**
  String get sponsors;

  /// No description provided for @author.
  ///
  /// In zh, this message translates to:
  /// **'作者'**
  String get author;

  /// No description provided for @independentDeveloper.
  ///
  /// In zh, this message translates to:
  /// **'独立开发者'**
  String get independentDeveloper;

  /// No description provided for @contributionsAndBugReportsAreWelcome.
  ///
  /// In zh, this message translates to:
  /// **'欢迎参与贡献或进行 bug 反馈'**
  String get contributionsAndBugReportsAreWelcome;

  /// No description provided for @homeScreenWidget.
  ///
  /// In zh, this message translates to:
  /// **'桌面小组件'**
  String get homeScreenWidget;

  /// No description provided for @addYourScheduleToTheHomeScreenForQuick.
  ///
  /// In zh, this message translates to:
  /// **'将课表添加到桌面，无需打开应用即可查看。'**
  String get addYourScheduleToTheHomeScreenForQuick;

  /// No description provided for @degreeProgress.
  ///
  /// In zh, this message translates to:
  /// **'大学进度'**
  String get degreeProgress;

  /// No description provided for @semesterProgress.
  ///
  /// In zh, this message translates to:
  /// **'本学期进度'**
  String get semesterProgress;

  /// No description provided for @timeline.
  ///
  /// In zh, this message translates to:
  /// **'日程'**
  String get timeline;

  /// No description provided for @today.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get today;

  /// No description provided for @noClassesToday.
  ///
  /// In zh, this message translates to:
  /// **'今天暂无课程'**
  String get noClassesToday;

  /// No description provided for @noUpcomingClasses.
  ///
  /// In zh, this message translates to:
  /// **'暂无即将发生课程'**
  String get noUpcomingClasses;

  /// No description provided for @upcoming2.
  ///
  /// In zh, this message translates to:
  /// **'即将发生'**
  String get upcoming2;

  /// No description provided for @jumpToAWeekOrDate.
  ///
  /// In zh, this message translates to:
  /// **'快速跳转周次/日期'**
  String get jumpToAWeekOrDate;

  /// No description provided for @goToWeek.
  ///
  /// In zh, this message translates to:
  /// **'跳转到周次'**
  String get goToWeek;

  /// No description provided for @goToASpecificWeek.
  ///
  /// In zh, this message translates to:
  /// **'跳转到指定周'**
  String get goToASpecificWeek;

  /// No description provided for @returnToCurrentWeek.
  ///
  /// In zh, this message translates to:
  /// **'回到当前周'**
  String get returnToCurrentWeek;

  /// No description provided for @switchToDayView.
  ///
  /// In zh, this message translates to:
  /// **'切换到日视图'**
  String get switchToDayView;

  /// No description provided for @switchToWeekView.
  ///
  /// In zh, this message translates to:
  /// **'切换到周视图'**
  String get switchToWeekView;

  /// No description provided for @weekSettings.
  ///
  /// In zh, this message translates to:
  /// **'周次设置'**
  String get weekSettings;

  /// No description provided for @periodsPerDay.
  ///
  /// In zh, this message translates to:
  /// **'每天节数'**
  String get periodsPerDay;

  /// No description provided for @semesterWeeks.
  ///
  /// In zh, this message translates to:
  /// **'学期周数'**
  String get semesterWeeks;

  /// No description provided for @semesterStartDate.
  ///
  /// In zh, this message translates to:
  /// **'开学日期'**
  String get semesterStartDate;

  /// No description provided for @showSaturday.
  ///
  /// In zh, this message translates to:
  /// **'显示周六'**
  String get showSaturday;

  /// No description provided for @showSunday.
  ///
  /// In zh, this message translates to:
  /// **'显示周日'**
  String get showSunday;

  /// No description provided for @showCoursesFromOtherWeeks.
  ///
  /// In zh, this message translates to:
  /// **'显示非本周课程'**
  String get showCoursesFromOtherWeeks;

  /// No description provided for @showCourseTimes.
  ///
  /// In zh, this message translates to:
  /// **'显示课程时间'**
  String get showCourseTimes;

  /// No description provided for @showFloatingJumpButton.
  ///
  /// In zh, this message translates to:
  /// **'显示悬浮跳转按钮'**
  String get showFloatingJumpButton;

  /// No description provided for @showHiddenAttendanceExemptCourses.
  ///
  /// In zh, this message translates to:
  /// **'显示已隐藏免听课程'**
  String get showHiddenAttendanceExemptCourses;

  /// No description provided for @showHiddenAttendanceExemptCoursesInTheSchedule.
  ///
  /// In zh, this message translates to:
  /// **'开启后在课表视图中显示已隐藏的免听课程'**
  String get showHiddenAttendanceExemptCoursesInTheSchedule;

  /// No description provided for @advancedSettings.
  ///
  /// In zh, this message translates to:
  /// **'高级设置'**
  String get advancedSettings;

  /// No description provided for @holidayScheduleAdjustments.
  ///
  /// In zh, this message translates to:
  /// **'节假日调休'**
  String get holidayScheduleAdjustments;

  /// No description provided for @scheduleAdjustment.
  ///
  /// In zh, this message translates to:
  /// **'调休设置'**
  String get scheduleAdjustment;

  /// No description provided for @moveClassesBetweenDates.
  ///
  /// In zh, this message translates to:
  /// **'指定日期课程调换'**
  String get moveClassesBetweenDates;

  /// No description provided for @chooseSourceDate.
  ///
  /// In zh, this message translates to:
  /// **'选择被调课程日期'**
  String get chooseSourceDate;

  /// No description provided for @chooseTargetDate.
  ///
  /// In zh, this message translates to:
  /// **'选择目标上课日期'**
  String get chooseTargetDate;

  /// No description provided for @dateA.
  ///
  /// In zh, this message translates to:
  /// **'日期A'**
  String get dateA;

  /// No description provided for @dateB.
  ///
  /// In zh, this message translates to:
  /// **'日期B'**
  String get dateB;

  /// No description provided for @confirmAdjustment.
  ///
  /// In zh, this message translates to:
  /// **'确认调休'**
  String get confirmAdjustment;

  /// No description provided for @scheduleAdjustmentCompleted.
  ///
  /// In zh, this message translates to:
  /// **'调休处理完成'**
  String get scheduleAdjustmentCompleted;

  /// No description provided for @theDatesMustBeDifferent.
  ///
  /// In zh, this message translates to:
  /// **'两个日期不能是同一天'**
  String get theDatesMustBeDifferent;

  /// No description provided for @chooseBothDatesFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先选择需要调整的日期'**
  String get chooseBothDatesFirst;

  /// No description provided for @details.
  ///
  /// In zh, this message translates to:
  /// **'详情'**
  String get details;

  /// No description provided for @menu.
  ///
  /// In zh, this message translates to:
  /// **'菜单'**
  String get menu;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get copied;

  /// No description provided for @confirmDeletion.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get confirmDeletion;

  /// No description provided for @thisCannotBeUndoneContinue.
  ///
  /// In zh, this message translates to:
  /// **'删除后无法恢复，是否继续？'**
  String get thisCannotBeUndoneContinue;

  /// No description provided for @anExamCannotLastLongerThan24Hours.
  ///
  /// In zh, this message translates to:
  /// **'单场考试时长不能超过24小时'**
  String get anExamCannotLastLongerThan24Hours;

  /// No description provided for @theEndTimeCannotBeEarlierThanTheStart.
  ///
  /// In zh, this message translates to:
  /// **'结束时间不能早于开始时间'**
  String get theEndTimeCannotBeEarlierThanTheStart;

  /// No description provided for @scheduleNameCannotBeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'课表名称不能为空'**
  String get scheduleNameCannotBeEmpty;

  /// No description provided for @thatScheduleNameAlreadyExistsChooseAnotherName.
  ///
  /// In zh, this message translates to:
  /// **'课表名称已存在，请使用其他名称'**
  String get thatScheduleNameAlreadyExistsChooseAnotherName;

  /// No description provided for @thereMustBeAtLeast10PeriodsPerDay.
  ///
  /// In zh, this message translates to:
  /// **'每天节数不能少于 10 节'**
  String get thereMustBeAtLeast10PeriodsPerDay;

  /// No description provided for @aSemesterMustContainAtLeast15Weeks.
  ///
  /// In zh, this message translates to:
  /// **'学期周数不能少于 15 周'**
  String get aSemesterMustContainAtLeast15Weeks;

  /// No description provided for @enterAValidWeekNumber.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的周次数字'**
  String get enterAValidWeekNumber;

  /// No description provided for @enterANickname.
  ///
  /// In zh, this message translates to:
  /// **'请输入昵称'**
  String get enterANickname;

  /// No description provided for @enterAMajor.
  ///
  /// In zh, this message translates to:
  /// **'请输入专业名称'**
  String get enterAMajor;

  /// No description provided for @enterACollege.
  ///
  /// In zh, this message translates to:
  /// **'请输入学院名称'**
  String get enterACollege;

  /// No description provided for @enterAClassName.
  ///
  /// In zh, this message translates to:
  /// **'请输入班级名称'**
  String get enterAClassName;

  /// No description provided for @enterACourseName.
  ///
  /// In zh, this message translates to:
  /// **'请输入课程名称'**
  String get enterACourseName;

  /// No description provided for @enterOrChooseAType.
  ///
  /// In zh, this message translates to:
  /// **'请输入或选择类型'**
  String get enterOrChooseAType;

  /// No description provided for @chooseAStartTime.
  ///
  /// In zh, this message translates to:
  /// **'请选择开始时间'**
  String get chooseAStartTime;

  /// No description provided for @chooseAnEndTime.
  ///
  /// In zh, this message translates to:
  /// **'请选择结束时间'**
  String get chooseAnEndTime;

  /// No description provided for @enterBothAStartAndEndTime.
  ///
  /// In zh, this message translates to:
  /// **'请完善开始和结束时间'**
  String get enterBothAStartAndEndTime;

  /// No description provided for @clearAllGradeDataThisCannotBeUndone.
  ///
  /// In zh, this message translates to:
  /// **'确定要清空所有成绩数据吗？此操作不可撤销。'**
  String get clearAllGradeDataThisCannotBeUndone;

  /// No description provided for @pressAndHoldToCopyTheContentBelow.
  ///
  /// In zh, this message translates to:
  /// **'以下内容可长按复制'**
  String get pressAndHoldToCopyTheContentBelow;

  /// No description provided for @filter.
  ///
  /// In zh, this message translates to:
  /// **'筛选: '**
  String get filter;

  /// No description provided for @classTime.
  ///
  /// In zh, this message translates to:
  /// **'上课时间'**
  String get classTime;

  /// No description provided for @sincereThanksToTheFollowingSponsorsListedInNo.
  ///
  /// In zh, this message translates to:
  /// **'衷心感谢以下用户对本项目的赞助（排名不分先后）'**
  String get sincereThanksToTheFollowingSponsorsListedInNo;

  /// No description provided for @forSupportJoinQQGroup1045770691.
  ///
  /// In zh, this message translates to:
  /// **'若遇到什么问题，请添加QQ群聊：1045770691 反馈问题'**
  String get forSupportJoinQQGroup1045770691;

  /// No description provided for @engineeringManagementDesign.
  ///
  /// In zh, this message translates to:
  /// **'工程  管理  设计'**
  String get engineeringManagementDesign;

  /// No description provided for @forInternationalStudents.
  ///
  /// In zh, this message translates to:
  /// **'留学生专用'**
  String get forInternationalStudents;

  /// No description provided for @holidayAdjustmentInstructionsThisMovesClassesFromDateA.
  ///
  /// In zh, this message translates to:
  /// **'节假日调休处理说明：\n该功能会将\"日期A\"的课程移动到\"日期B\"。移动逻辑为：\n1. 将日期A的课程剪切到日期B。\n2. 日期B该天的原有课程会被清空。\n3. 注意：仅对指定日期的单日课程生效，不影响整个学期的其他同安排课程。'**
  String get holidayAdjustmentInstructionsThisMovesClassesFromDateA;

  /// No description provided for @gradeAndGpaCalculationsInThisAppAreFor.
  ///
  /// In zh, this message translates to:
  /// **'本应用提供的成绩计算及绩点统计功能仅供参考。\n\n由于学校教务系统可能会调整计算规则，或者存在特殊课程（如未评教、重修、免修、缓考等）的处理差异，本应用的计算结果可能与官方教务系统存在细微偏差。\n\n请最终以教务系统发布的正式成绩单为准，开发者不对因使用本数据造成的任何问题承担责任。'**
  String get gradeAndGpaCalculationsInThisAppAreFor;

  /// No description provided for @exportFailedWithError.
  ///
  /// In zh, this message translates to:
  /// **'导出失败：{error}'**
  String exportFailedWithError(String error);

  /// No description provided for @processingFailedWithError.
  ///
  /// In zh, this message translates to:
  /// **'处理失败：{error}'**
  String processingFailedWithError(String error);

  /// No description provided for @extractionFailedWithError.
  ///
  /// In zh, this message translates to:
  /// **'提取失败：{error}'**
  String extractionFailedWithError(String error);

  /// No description provided for @genericErrorWithDetail.
  ///
  /// In zh, this message translates to:
  /// **'发生错误：{error}'**
  String genericErrorWithDetail(String error);

  /// No description provided for @avatarUploadFailedWithError.
  ///
  /// In zh, this message translates to:
  /// **'头像上传失败：{error}'**
  String avatarUploadFailedWithError(String error);

  /// No description provided for @periodNumberWithTime.
  ///
  /// In zh, this message translates to:
  /// **'第 {period} 节 {time}'**
  String periodNumberWithTime(int period, String time);

  /// No description provided for @periodRange.
  ///
  /// In zh, this message translates to:
  /// **'第 {start} - {end} 节'**
  String periodRange(int start, int end);

  /// No description provided for @weekRange.
  ///
  /// In zh, this message translates to:
  /// **'第 {start} - {end} 周'**
  String weekRange(int start, int end);

  /// No description provided for @startsOnDate.
  ///
  /// In zh, this message translates to:
  /// **'开学：{date}'**
  String startsOnDate(String date);

  /// No description provided for @deleteCourseQuestion.
  ///
  /// In zh, this message translates to:
  /// **'确认要删除课程“{name}”吗？'**
  String deleteCourseQuestion(String name);

  /// No description provided for @deleteItemQuestion.
  ///
  /// In zh, this message translates to:
  /// **'确认要删除“{name}”吗？'**
  String deleteItemQuestion(String name);

  /// No description provided for @deleteScheduleQuestion.
  ///
  /// In zh, this message translates to:
  /// **'确认要删除课表“{name}”吗？\n删除后该课表下的所有课程也会被清空。'**
  String deleteScheduleQuestion(String name);

  /// No description provided for @weekOutOfRange.
  ///
  /// In zh, this message translates to:
  /// **'周次超出范围，请输入 1-{maxWeek}'**
  String weekOutOfRange(int maxWeek);

  /// No description provided for @weekInputLabel.
  ///
  /// In zh, this message translates to:
  /// **'周次（1-{maxWeek}）'**
  String weekInputLabel(int maxWeek);

  /// No description provided for @importedCourses.
  ///
  /// In zh, this message translates to:
  /// **'成功导入 {courseCount} 门课程（共 {recordCount} 条记录）'**
  String importedCourses(int courseCount, int recordCount);

  /// No description provided for @updatedProfile.
  ///
  /// In zh, this message translates to:
  /// **'已更新：{name}{code}'**
  String updatedProfile(String name, String code);

  /// No description provided for @updatedProfileInformation.
  ///
  /// In zh, this message translates to:
  /// **'已更新信息：{name}{studentId}'**
  String updatedProfileInformation(String name, String studentId);

  /// No description provided for @parsingSemesterInformation.
  ///
  /// In zh, this message translates to:
  /// **'正在解析学期信息（{count} 个）……'**
  String parsingSemesterInformation(int count);

  /// No description provided for @semesterFallbackName.
  ///
  /// In zh, this message translates to:
  /// **'学期 {id}'**
  String semesterFallbackName(String id);

  /// No description provided for @fetchingSemesterSchedule.
  ///
  /// In zh, this message translates to:
  /// **'正在抓取 {semester} 课表……'**
  String fetchingSemesterSchedule(String semester);

  /// No description provided for @retrievingScoresForSemesters.
  ///
  /// In zh, this message translates to:
  /// **'正在提取成绩（共 {count} 个学期）……'**
  String retrievingScoresForSemesters(int count);

  /// No description provided for @noScoresForSemesters.
  ///
  /// In zh, this message translates to:
  /// **'未检测到成绩数据（学期数：{count}）'**
  String noScoresForSemesters(int count);

  /// No description provided for @importedScoreRecords.
  ///
  /// In zh, this message translates to:
  /// **'成功导入 {count} 条成绩记录！'**
  String importedScoreRecords(int count);

  /// No description provided for @retrievingExamsAttempt.
  ///
  /// In zh, this message translates to:
  /// **'正在提取考试安排……（第 {attempt} 次尝试）'**
  String retrievingExamsAttempt(int attempt);

  /// No description provided for @daysInAdvanceValue.
  ///
  /// In zh, this message translates to:
  /// **'提前 {days} 天'**
  String daysInAdvanceValue(int days);

  /// No description provided for @retrievingExams.
  ///
  /// In zh, this message translates to:
  /// **'正在提取考试安排……'**
  String get retrievingExams;

  /// No description provided for @examReminderAt.
  ///
  /// In zh, this message translates to:
  /// **'考试前 {days} 天 {time} 提醒'**
  String examReminderAt(int days, String time);

  /// No description provided for @examDaysBefore.
  ///
  /// In zh, this message translates to:
  /// **'考试前 {days} 天'**
  String examDaysBefore(int days);

  /// No description provided for @lastImportedAt.
  ///
  /// In zh, this message translates to:
  /// **'上次导入成绩时间 {time}'**
  String lastImportedAt(String time);

  /// No description provided for @unevaluatedCoursesExcludedFromGpa.
  ///
  /// In zh, this message translates to:
  /// **'本学期有 {count} 门课程未评教，不计入 GPA'**
  String unevaluatedCoursesExcludedFromGpa(int count);

  /// No description provided for @creditsValue.
  ///
  /// In zh, this message translates to:
  /// **'学分：{value}'**
  String creditsValue(String value);

  /// No description provided for @semesterWeekPosition.
  ///
  /// In zh, this message translates to:
  /// **'{semester} · 第 {week} 周 · {weekday}'**
  String semesterWeekPosition(String semester, int week, String weekday);

  /// No description provided for @scheduleEventDate.
  ///
  /// In zh, this message translates to:
  /// **'{month}月{day}日 {weekday}  {startTime}-{endTime}'**
  String scheduleEventDate(
    int month,
    int day,
    String weekday,
    String startTime,
    String endTime,
  );

  /// No description provided for @courseScheduleLine.
  ///
  /// In zh, this message translates to:
  /// **'{weekday} {periods} {time}'**
  String courseScheduleLine(String weekday, String periods, String time);

  /// No description provided for @examCopyText.
  ///
  /// In zh, this message translates to:
  /// **'{course}\n时间：{time}\n地点：{location}'**
  String examCopyText(String course, String time, String location);

  /// No description provided for @courseDetails.
  ///
  /// In zh, this message translates to:
  /// **'课程详情'**
  String get courseDetails;

  /// No description provided for @courseCatalogDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'该页面仅供参考，请以教务系统为准'**
  String get courseCatalogDisclaimer;

  /// No description provided for @semesterCourseCount.
  ///
  /// In zh, this message translates to:
  /// **'本学期课程数量'**
  String get semesterCourseCount;

  /// No description provided for @semesterTotalCredits.
  ///
  /// In zh, this message translates to:
  /// **'本学期总学分'**
  String get semesterTotalCredits;

  /// No description provided for @courseCode.
  ///
  /// In zh, this message translates to:
  /// **'课程代码'**
  String get courseCode;

  /// No description provided for @courseType.
  ///
  /// In zh, this message translates to:
  /// **'课程类型'**
  String get courseType;

  /// No description provided for @assessmentMethod.
  ///
  /// In zh, this message translates to:
  /// **'考核方式'**
  String get assessmentMethod;

  /// No description provided for @offeringDepartment.
  ///
  /// In zh, this message translates to:
  /// **'开课部门'**
  String get offeringDepartment;

  /// No description provided for @teachingFormat.
  ///
  /// In zh, this message translates to:
  /// **'教学形式'**
  String get teachingFormat;

  /// No description provided for @totalClassHours.
  ///
  /// In zh, this message translates to:
  /// **'总学时'**
  String get totalClassHours;

  /// No description provided for @teachingWeeks.
  ///
  /// In zh, this message translates to:
  /// **'教学周数'**
  String get teachingWeeks;

  /// No description provided for @classHourBreakdown.
  ///
  /// In zh, this message translates to:
  /// **'学时组成'**
  String get classHourBreakdown;

  /// No description provided for @theoryHours.
  ///
  /// In zh, this message translates to:
  /// **'理论'**
  String get theoryHours;

  /// No description provided for @practiceHours.
  ///
  /// In zh, this message translates to:
  /// **'实践'**
  String get practiceHours;

  /// No description provided for @focusedPracticeHours.
  ///
  /// In zh, this message translates to:
  /// **'集中实践'**
  String get focusedPracticeHours;

  /// No description provided for @dispersedPracticeHours.
  ///
  /// In zh, this message translates to:
  /// **'分散实践'**
  String get dispersedPracticeHours;

  /// No description provided for @assessmentHours.
  ///
  /// In zh, this message translates to:
  /// **'考核'**
  String get assessmentHours;

  /// No description provided for @experimentHours.
  ///
  /// In zh, this message translates to:
  /// **'实验'**
  String get experimentHours;

  /// No description provided for @computerHours.
  ///
  /// In zh, this message translates to:
  /// **'上机'**
  String get computerHours;

  /// No description provided for @designHours.
  ///
  /// In zh, this message translates to:
  /// **'设计'**
  String get designHours;

  /// No description provided for @extracurricularHours.
  ///
  /// In zh, this message translates to:
  /// **'课外'**
  String get extracurricularHours;

  /// No description provided for @courseCreditValue.
  ///
  /// In zh, this message translates to:
  /// **'{value} 学分'**
  String courseCreditValue(String value);

  /// No description provided for @requiredField.
  ///
  /// In zh, this message translates to:
  /// **'请输入{field}'**
  String requiredField(String field);
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
