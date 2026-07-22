// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '三旋翼课程表';

  @override
  String get schedule => '课表';

  @override
  String get transcript => '成绩';

  @override
  String get exams => '考试';

  @override
  String get profile => '我的';

  @override
  String get settings => '设置';

  @override
  String get general => '通用';

  @override
  String get notifications => '通知';

  @override
  String get appearanceAndDisplay => '界面与显示';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get dataAndPrivacy => '数据与隐私';

  @override
  String get clearAllData => '清除所有数据';

  @override
  String get clearAllDataSubtitle => '包括课表、成绩、个人信息及偏好设置';

  @override
  String get clearAllDataQuestion => '清除所有数据？';

  @override
  String get clearAllDataWarning =>
      '此操作不可撤销。所有本地存储的课表、成绩、个人设置等都将被永久删除，App 将恢复到初始状态。';

  @override
  String get cancel => '取消';

  @override
  String get confirmClear => '确认清除';

  @override
  String get confirmAgain => '再次确认';

  @override
  String get confirmClearFinal => '真的要删除所有数据吗？数据一旦清除将无法找回。';

  @override
  String get dataClearedRestart => '数据已清除，请重启应用';

  @override
  String clearFailed(String error) {
    return '清除失败：$error';
  }

  @override
  String get userAgreementAndPrivacy => '用户协议与隐私政策';

  @override
  String get welcomeAgreement => '欢迎使用三旋翼课程表（My SUES）。在使用本应用前，请您仔细阅读并同意以下协议：';

  @override
  String get userAgreement => '用户协议';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get agreementFraudWarning =>
      '重要提示：本产品为公益性质的完全免费产品，若您是通过付费获取本产品，那您遭遇了诈骗。';

  @override
  String get disagreeAndExit => '不同意并退出';

  @override
  String get agreeAndContinue => '同意并继续';

  @override
  String get agreementConsentHint => '点击“同意并继续”表示您已阅读并同意以上协议。';

  @override
  String get legalChinesePrevails => '英文译文仅供参考，如有歧义，以中文版本为准。';

  @override
  String get defaultSchedule => '默认课表';

  @override
  String get scheduleNotConfigured => '未设置课表';

  @override
  String get noCoursesToday => '今日无课';

  @override
  String get openAppToUpdateSchedule => '请打开 App 更新课表';

  @override
  String get enjoyFreeTime => '享受美好的空闲时光～';

  @override
  String weekNumber(int week) {
    return '第 $week 周';
  }

  @override
  String weekdayShort(int month, int day, String weekday) {
    return '$month.$day 周$weekday';
  }

  @override
  String get mondayShort => '一';

  @override
  String get tuesdayShort => '二';

  @override
  String get wednesdayShort => '三';

  @override
  String get thursdayShort => '四';

  @override
  String get fridayShort => '五';

  @override
  String get saturdayShort => '六';

  @override
  String get sundayShort => '日';

  @override
  String get courseReminder => '课程提醒';

  @override
  String get courseReminderDescription => '上课前 15 分钟提醒';

  @override
  String get classroomLabel => '教室';

  @override
  String get timeLabel => '时间';

  @override
  String get locationLabel => '地点';

  @override
  String courseStartsSoon(String course, String room) {
    return '$course 将在 15 分钟后开始$room';
  }

  @override
  String get examReminder => '考试提醒';

  @override
  String examReminderDescription(int days) {
    return '考试前 $days 天提醒';
  }

  @override
  String get tomorrow => '明天';

  @override
  String daysLater(int days) {
    return '$days 天后';
  }

  @override
  String examReminderBody(
    String course,
    String dayText,
    String time,
    String location,
  ) {
    return '$course $dayText考试$time$location';
  }

  @override
  String get widgetDisplayName => '课表小组件';

  @override
  String get widgetDescription => '快速查看今日课表，让你不再错过任何一节课。';

  @override
  String get mon => '周一';

  @override
  String get tue => '周二';

  @override
  String get wed => '周三';

  @override
  String get thu => '周四';

  @override
  String get fri => '周五';

  @override
  String get sat => '周六';

  @override
  String get sun => '周日';

  @override
  String get mySuesByHsxMark => '三旋翼课程表 by HsxMark';

  @override
  String get mySchedule => '我的课表';

  @override
  String get profile2 => '我';

  @override
  String get attendanceExempt => '[免听]';

  @override
  String get retake => '[重修]';

  @override
  String get outsideThisWeek => '[非本周]';

  @override
  String get fourYearProgram => '(肆年制)';

  @override
  String get save => '保存';

  @override
  String get confirm => '确认';

  @override
  String get ok => '确定';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get close => '关闭';

  @override
  String get skip => '跳过';

  @override
  String get next => '下一步';

  @override
  String get go => '跳转';

  @override
  String get all => '全部';

  @override
  String get noData => '无数据';

  @override
  String get notSet => '未设置';

  @override
  String get setValue => '已设置';

  @override
  String get notSelected => '未选择';

  @override
  String get unknown => '未知';

  @override
  String get unknownSemester => '未知学期';

  @override
  String get signIn => '登录';

  @override
  String get academicSystem => '教务系统';

  @override
  String get signInToYourAccount => '请登录您的账号';

  @override
  String get signedInUseTheButtonsBelowToRetrieveYour => '登录成功，请点击下方按钮提取数据';

  @override
  String get webVpnDataImport => 'WebVPN 网页提取';

  @override
  String get clearCache => '清理缓存';

  @override
  String get cacheCleared => '缓存已清理';

  @override
  String get chooseTheDataToRetrieve => '请选择要提取的内容';

  @override
  String get chooseASemesterToImport => '请选择导入学期';

  @override
  String get importMenu => '提取菜单';

  @override
  String get retrieveProfile => '提取个人信息';

  @override
  String get retrieveSchedule => '提取课表';

  @override
  String get retrieveGrades => '提取成绩';

  @override
  String get retrieveExams => '提取考试安排';

  @override
  String get extractionFailedTryAgain => '提取失败，请重试';

  @override
  String get requestFailedTryAgain => '抓取失败，请重试';

  @override
  String get failedToRetrieveScheduleData => '抓取课表数据失败';

  @override
  String get openingTheSchedulePageToRetrieveData => '跳转到课表页面以获取数据...';

  @override
  String get waitingForThePageToLoad => '正在等待页面加载...';

  @override
  String get openingTheAcademicSystem => '正在跳转到教务系统...';

  @override
  String get openingTheSchedulePage => '正在跳转到课表页面...';

  @override
  String get retrievingBasicData => '正在获取基础数据...';

  @override
  String get retrievingSemesters => '正在获取学期列表...';

  @override
  String get parsing => '正在解析...';

  @override
  String get parsingStudentInformation => '正在解析学生信息...';

  @override
  String get retrievingProfile => '正在提取个人信息...';

  @override
  String get savingCourseData => '正在保存课程数据...';

  @override
  String get pageLoadingTimedOutTryAgain => '页面加载超时，请重试';

  @override
  String get thePageIsNotReadyTryAgain => '页面未就绪，请重试';

  @override
  String get noDataReceivedWaitingToRetry => '未获取到数据，等待重试...';

  @override
  String get noProfileInformationWasFound => '未检测到个人信息';

  @override
  String get noExamDataWasFound => '未检测到考试数据';

  @override
  String get noExamDataWasFound2 => '未找到考试数据';

  @override
  String get noSemesterListWasFoundTryAgain => '未找到学期列表，请重试';

  @override
  String get noCoursesCouldBeParsed => '未能解析出任何课程';

  @override
  String get noValidProfileInformationCouldBeExtracted => '未能提取到有效的个人信息';

  @override
  String get unableToParseTheScheduleData => '无法从课表数据中解析...';

  @override
  String get unableToRetrieveSemestersTryAgain => '无法获取学期列表，请重试';

  @override
  String get unableToRetrieveStudentInformationTryAgain => '无法获取学生信息，请重试';

  @override
  String get failedToRetrieveStudentInformation => '获取学生信息失败';

  @override
  String get operationCancelled => '用户取消操作';

  @override
  String get appearance => '外观';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get lightMode => '浅色模式';

  @override
  String get darkMode => '深色模式';

  @override
  String get setBackgroundImage => '设置背景图片';

  @override
  String get backgroundOpacity => '背景透明度';

  @override
  String get splashAnimation => '开屏动画';

  @override
  String get showTheSplashAnimationWhenTheAppStarts => '启动应用时显示开屏动画';

  @override
  String get experimentalFeatures => '实验性功能';

  @override
  String get experimentalAppearance => '实验性外观';

  @override
  String get experimentalAppearanceMayReduceContrastOrPerformanceOnSome =>
      '实验性外观可能降低部分页面的对比度或性能，默认 Material You 外观不受影响。';

  @override
  String get liquidGlassEffectBETA => '液态玻璃效果 (BETA)';

  @override
  String get addsAFrostedGlassAppearanceToTheInterface => '开启后界面将呈现磨砂玻璃质感';

  @override
  String get profile3 => '个人资料';

  @override
  String get nickname => '昵称';

  @override
  String get studentID => '学号';

  @override
  String get name => '姓名';

  @override
  String get major => '专业';

  @override
  String get college => '学院';

  @override
  String get classLabel => '班级';

  @override
  String get year => '年级';

  @override
  String get changeNickname => '修改昵称';

  @override
  String get changeMajor => '修改专业';

  @override
  String get changeCollege => '修改学院';

  @override
  String get changeClass => '修改班级';

  @override
  String get avatar => '头像';

  @override
  String get lastSync => '上次同步时间';

  @override
  String get connectToTheAcademicSystemToSyncYourProfile => '请连接教务系统同步身份信息';

  @override
  String get academicSync => '教务同步';

  @override
  String get synced => '已同步';

  @override
  String get notSynced => '未同步';

  @override
  String get tapToSync => '点击开始同步';

  @override
  String get signInToTheAcademicSystem => '请登录 教务系统';

  @override
  String get enterMySues => '进入 三旋翼课程表';

  @override
  String get welcomeToMySues => '欢迎使用三旋翼课程表 My SUES';

  @override
  String get yourAllInOneCampusAssistantForASimpler => '一站式校园信息助手，让你的校园生活更便捷。';

  @override
  String get viewWeeklyOrDailyClassesAndImportSchedulesFrom =>
      '快速查看每周或每日课程安排，支持导入教务系统课表。';

  @override
  String get reviewGradesAndGpaWheneverYouNeedThem => '随时查看各科成绩与绩点，掌握学业情况。';

  @override
  String get keepTrackOfExamTimesAndLocations => '及时获取考试时间与地点，不错过每场考试。';

  @override
  String get viewSchedule => '查看课表';

  @override
  String get viewGrades => '查看个人成绩';

  @override
  String get viewExams => '查看考试信息';

  @override
  String get schedule2 => '课程表';

  @override
  String get dailySchedule => '每日课表';

  @override
  String get scheduleSettings => '课表设置';

  @override
  String get scheduleDisplay => '课表显示设置';

  @override
  String get scheduleName => '课表名称';

  @override
  String get newSchedule => '新课表';

  @override
  String get newSchedule2 => '新建课表';

  @override
  String get switchSchedule => '切换课表';

  @override
  String get deleteSchedule => '删除课表';

  @override
  String get pressAndHoldToDeleteASchedule => '长按删除课表';

  @override
  String get noScheduleFoundCreateOneFirst => '没有课表数据，请先创建课表';

  @override
  String get syncExam => '同步考试';

  @override
  String get syncSchedule => '同步课表';

  @override
  String get syncGrades => '同步成绩';

  @override
  String get cancelImport => '取消导入';

  @override
  String get importCancelled => '已取消导入';

  @override
  String get exportIcs => '导出 ICS';

  @override
  String get exportScheduleIcs => '导出课表 (.ics)';

  @override
  String get exportScheduleIcs2 => '导出课表(.ics)';

  @override
  String get thereAreNoCoursesToExport => '当前没有课程可以导出';

  @override
  String get course => '课程';

  @override
  String get courseName => '课程名称';

  @override
  String get instructor => '老师';

  @override
  String get weekday => '星期';

  @override
  String get startWeek => '开始周';

  @override
  String get endWeek => '结束周';

  @override
  String get startPeriod => '开始节次';

  @override
  String get endPeriod => '结束节次';

  @override
  String get startTime => '开始时间';

  @override
  String get endTime => '结束时间';

  @override
  String get startTimeHHMm => '开始时间(HH:mm)';

  @override
  String get endTimeHHMm => '结束时间(HH:mm)';

  @override
  String get weekPattern => '单双周';

  @override
  String get everyWeek => '每周';

  @override
  String get oddWeeks => '单周';

  @override
  String get evenWeeks => '双周';

  @override
  String get courseColor => '课程颜色';

  @override
  String get studyStatus => '修读状态';

  @override
  String get normal => '正常修读';

  @override
  String get retake2 => '重修';

  @override
  String get attendanceExempt2 => '免听';

  @override
  String get editCourse => '编辑课程';

  @override
  String get addCourse => '添加课程';

  @override
  String get deleteCourse => '删除课程';

  @override
  String get copyCourseName => '复制课程名称';

  @override
  String get copyCourseDetailsAsText => '复制课程信息为文本';

  @override
  String get courseNameCopied => '已复制课程名称';

  @override
  String get courseDetailsCopied => '已复制课程信息';

  @override
  String get warningCourseConflict => '注意：存在课程冲突';

  @override
  String get theFollowingCoursesOverlap => '您有以下课程在同一时间段产生冲突：';

  @override
  String get saveAnywayYouCanViewThemInTheSchedule =>
      '是否继续保存？您可以在课表中正常查看它们，或后续修改免听/重修状态。';

  @override
  String get saveAnyway => '继续保存';

  @override
  String get hideThisCourseFromTheSchedule => '是否在课表中隐藏？';

  @override
  String get hiddenCoursesAreNotShownInTheScheduleView => '隐藏后将不会在课表视图中显示该课程';

  @override
  String get grades => '成绩单';

  @override
  String get gpa => '绩点';

  @override
  String get credits => '学分';

  @override
  String get credits2 => '修读学分';

  @override
  String get semesterGpa => '学期 GPA';

  @override
  String get semester => '学期详情';

  @override
  String get overallGpa => '总平均绩点 (GPA)';

  @override
  String get courseCredits => '课程 学分...';

  @override
  String get pending => '未评教';

  @override
  String get noGradesYetImportThemFromTheMenu => '暂无成绩数据，点击右上方按钮进行导入';

  @override
  String get importTranscript => '导入成绩单';

  @override
  String get gradeInformation => '成绩说明';

  @override
  String get clearGrades => '清空成绩';

  @override
  String get clear => '确认清空';

  @override
  String get failed => '挂科';

  @override
  String get deferredExam => '缓考';

  @override
  String get examInformation => '考试信息';

  @override
  String get examScheduleImported => '考试安排导入成功';

  @override
  String get addExam => '添加考试';

  @override
  String get editExam => '编辑考试';

  @override
  String get saveExam => '保存考试信息';

  @override
  String get examInformationMayNotBeCurrentAlwaysConfirmIt =>
      '考试信息非即时获取，仅供参考，请以教务处系统提示为准！';

  @override
  String get noMatchingExams => '暂无符合条件的考试信息';

  @override
  String get clearFinished => '清除已结束';

  @override
  String get allFinishedExamsWereCleared => '已清除所有已结束的考试';

  @override
  String get examTodayCheckTheTimeCarefully => '今日考试，请注意时间！';

  @override
  String get copyExamName => '复制考试名称';

  @override
  String get copyExamDetailsAsText => '复制考试信息为文本';

  @override
  String get examNameCopied => '已复制考试名称';

  @override
  String get examDetailsCopied => '已复制考试信息';

  @override
  String get typeLabel => '类型';

  @override
  String get status => '当前状态';

  @override
  String get notStarted => '未开始';

  @override
  String get upcoming => '未结束';

  @override
  String get inProgress => '进行中';

  @override
  String get finished => '已结束';

  @override
  String get midterm => '期中';

  @override
  String get finalExam => '期末';

  @override
  String get makeUpExam => '补考';

  @override
  String get remindMe15MinutesBeforeClass => '上课前15分钟提醒';

  @override
  String get notificationPermissionIsRequiredForClassReminders =>
      '需要通知权限才能设置课程提醒';

  @override
  String get notificationPermissionIsRequiredForExamReminders =>
      '需要通知权限才能设置考试提醒';

  @override
  String get classRemindersEnabled => '已开启课程提醒';

  @override
  String get classRemindersDisabled => '已关闭课程提醒';

  @override
  String get examRemindersEnabled => '已开启考试提醒';

  @override
  String get examRemindersDisabled => '已关闭考试提醒';

  @override
  String get daysBefore => '提前几天提醒';

  @override
  String get daysInAdvance => '提前天数';

  @override
  String get reminderTime => '提醒时间';

  @override
  String get chooseReminderTime => '选择提醒时间';

  @override
  String get enableToChooseACustomReminderTime => '开启后可自定义提醒时间';

  @override
  String get about => '关于';

  @override
  String get projectInformation => '项目信息';

  @override
  String get tutorial => '软件介绍';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get openSource => '开源信息';

  @override
  String get disclaimer => '免责声明';

  @override
  String get thisFeatureProvidesAConvenientWayToSyncInformation =>
      '本功能仅提供便捷的信息同步服务，导入的数据可能存在偏差。请仔细核对同步后的信息，一切以教务处网站显示为准。';

  @override
  String get doNotShowAgain => '不再显示';

  @override
  String get appIntegrityWarningTitle => '应用来源无法确认';

  @override
  String get appIntegrityWarningMessage =>
      '无法确认此应用来自官方发布渠道。它可能已被第三方修改，存在账号、数据或设备安全风险。建议立即卸载，并从官方网站重新下载。';

  @override
  String get appIntegrityRiskAcknowledgement =>
      '开发者无法保证此版本的安全性。继续使用即表示您已了解并自行承担相关风险与损失。';

  @override
  String get downloadOfficialVersion => '前往官方网站下载';

  @override
  String get continueUsing => '继续使用';

  @override
  String get officialDownloadOpenFailed => '无法打开官方网站，请稍后重试。';

  @override
  String get doNotRemindAtStartup => '不再提醒';

  @override
  String get iUnderstand => '我已知悉';

  @override
  String get processing => '处理中...';

  @override
  String get acknowledgements => '鸣谢';

  @override
  String get sponsors => '赞助者';

  @override
  String get author => '作者';

  @override
  String get independentDeveloper => '独立开发者';

  @override
  String get contributionsAndBugReportsAreWelcome => '欢迎参与贡献或进行 bug 反馈';

  @override
  String get homeScreenWidget => '桌面小组件';

  @override
  String get addYourScheduleToTheHomeScreenForQuick => '将课表添加到桌面，无需打开应用即可查看。';

  @override
  String get degreeProgress => '大学进度';

  @override
  String get semesterProgress => '本学期进度';

  @override
  String get timeline => '日程';

  @override
  String get today => '今天';

  @override
  String get noClassesToday => '今天暂无课程';

  @override
  String get noUpcomingClasses => '暂无即将发生课程';

  @override
  String get upcoming2 => '即将发生';

  @override
  String get jumpToAWeekOrDate => '快速跳转周次/日期';

  @override
  String get goToWeek => '跳转到周次';

  @override
  String get goToASpecificWeek => '跳转到指定周';

  @override
  String get returnToCurrentWeek => '回到当前周';

  @override
  String get switchToDayView => '切换到日视图';

  @override
  String get switchToWeekView => '切换到周视图';

  @override
  String get weekSettings => '周次设置';

  @override
  String get periodsPerDay => '每天节数';

  @override
  String get semesterWeeks => '学期周数';

  @override
  String get semesterStartDate => '开学日期';

  @override
  String get showSaturday => '显示周六';

  @override
  String get showSunday => '显示周日';

  @override
  String get showCoursesFromOtherWeeks => '显示非本周课程';

  @override
  String get showCourseTimes => '显示课程时间';

  @override
  String get showFloatingJumpButton => '显示悬浮跳转按钮';

  @override
  String get showHiddenAttendanceExemptCourses => '显示已隐藏免听课程';

  @override
  String get showHiddenAttendanceExemptCoursesInTheSchedule =>
      '开启后在课表视图中显示已隐藏的免听课程';

  @override
  String get advancedSettings => '高级设置';

  @override
  String get holidayScheduleAdjustments => '节假日调休';

  @override
  String get scheduleAdjustment => '调休设置';

  @override
  String get moveClassesBetweenDates => '指定日期课程调换';

  @override
  String get chooseSourceDate => '选择被调课程日期';

  @override
  String get chooseTargetDate => '选择目标上课日期';

  @override
  String get dateA => '日期A';

  @override
  String get dateB => '日期B';

  @override
  String get confirmAdjustment => '确认调休';

  @override
  String get scheduleAdjustmentCompleted => '调休处理完成';

  @override
  String get theDatesMustBeDifferent => '两个日期不能是同一天';

  @override
  String get chooseBothDatesFirst => '请先选择需要调整的日期';

  @override
  String get details => '详情';

  @override
  String get menu => '菜单';

  @override
  String get copied => '已复制';

  @override
  String get confirmDeletion => '确认删除';

  @override
  String get thisCannotBeUndoneContinue => '删除后无法恢复，是否继续？';

  @override
  String get anExamCannotLastLongerThan24Hours => '单场考试时长不能超过24小时';

  @override
  String get theEndTimeCannotBeEarlierThanTheStart => '结束时间不能早于开始时间';

  @override
  String get scheduleNameCannotBeEmpty => '课表名称不能为空';

  @override
  String get thatScheduleNameAlreadyExistsChooseAnotherName =>
      '课表名称已存在，请使用其他名称';

  @override
  String get thereMustBeAtLeast10PeriodsPerDay => '每天节数不能少于 10 节';

  @override
  String get aSemesterMustContainAtLeast15Weeks => '学期周数不能少于 15 周';

  @override
  String get enterAValidWeekNumber => '请输入有效的周次数字';

  @override
  String get enterANickname => '请输入昵称';

  @override
  String get enterAMajor => '请输入专业名称';

  @override
  String get enterACollege => '请输入学院名称';

  @override
  String get enterAClassName => '请输入班级名称';

  @override
  String get enterACourseName => '请输入课程名称';

  @override
  String get enterOrChooseAType => '请输入或选择类型';

  @override
  String get chooseAStartTime => '请选择开始时间';

  @override
  String get chooseAnEndTime => '请选择结束时间';

  @override
  String get enterBothAStartAndEndTime => '请完善开始和结束时间';

  @override
  String get clearAllGradeDataThisCannotBeUndone => '确定要清空所有成绩数据吗？此操作不可撤销。';

  @override
  String get pressAndHoldToCopyTheContentBelow => '以下内容可长按复制';

  @override
  String get filter => '筛选: ';

  @override
  String get classTime => '上课时间';

  @override
  String get sincereThanksToTheFollowingSponsorsListedInNo =>
      '衷心感谢以下用户对本项目的赞助（排名不分先后）';

  @override
  String get forSupportJoinQQGroup1045770691 =>
      '若遇到什么问题，请添加QQ群聊：1045770691 反馈问题';

  @override
  String get engineeringManagementDesign => '工程  管理  设计';

  @override
  String get forInternationalStudents => '留学生专用';

  @override
  String get holidayAdjustmentInstructionsThisMovesClassesFromDateA =>
      '节假日调休处理说明：\n该功能会将\"日期A\"的课程移动到\"日期B\"。移动逻辑为：\n1. 将日期A的课程剪切到日期B。\n2. 日期B该天的原有课程会被清空。\n3. 注意：仅对指定日期的单日课程生效，不影响整个学期的其他同安排课程。';

  @override
  String get gradeAndGpaCalculationsInThisAppAreFor =>
      '本应用提供的成绩计算及绩点统计功能仅供参考。\n\n由于学校教务系统可能会调整计算规则，或者存在特殊课程（如未评教、重修、免修、缓考等）的处理差异，本应用的计算结果可能与官方教务系统存在细微偏差。\n\n请最终以教务系统发布的正式成绩单为准，开发者不对因使用本数据造成的任何问题承担责任。';

  @override
  String exportFailedWithError(String error) {
    return '导出失败：$error';
  }

  @override
  String processingFailedWithError(String error) {
    return '处理失败：$error';
  }

  @override
  String extractionFailedWithError(String error) {
    return '提取失败：$error';
  }

  @override
  String genericErrorWithDetail(String error) {
    return '发生错误：$error';
  }

  @override
  String avatarUploadFailedWithError(String error) {
    return '头像上传失败：$error';
  }

  @override
  String periodNumberWithTime(int period, String time) {
    return '第 $period 节 $time';
  }

  @override
  String periodRange(int start, int end) {
    return '第 $start - $end 节';
  }

  @override
  String weekRange(int start, int end) {
    return '第 $start - $end 周';
  }

  @override
  String startsOnDate(String date) {
    return '开学：$date';
  }

  @override
  String deleteCourseQuestion(String name) {
    return '确认要删除课程“$name”吗？';
  }

  @override
  String deleteItemQuestion(String name) {
    return '确认要删除“$name”吗？';
  }

  @override
  String deleteScheduleQuestion(String name) {
    return '确认要删除课表“$name”吗？\n删除后该课表下的所有课程也会被清空。';
  }

  @override
  String weekOutOfRange(int maxWeek) {
    return '周次超出范围，请输入 1-$maxWeek';
  }

  @override
  String weekInputLabel(int maxWeek) {
    return '周次（1-$maxWeek）';
  }

  @override
  String importedCourses(int courseCount, int recordCount) {
    return '成功导入 $courseCount 门课程（共 $recordCount 条记录）';
  }

  @override
  String updatedProfile(String name, String code) {
    return '已更新：$name$code';
  }

  @override
  String updatedProfileInformation(String name, String studentId) {
    return '已更新信息：$name$studentId';
  }

  @override
  String parsingSemesterInformation(int count) {
    return '正在解析学期信息（$count 个）……';
  }

  @override
  String semesterFallbackName(String id) {
    return '学期 $id';
  }

  @override
  String fetchingSemesterSchedule(String semester) {
    return '正在抓取 $semester 课表……';
  }

  @override
  String retrievingScoresForSemesters(int count) {
    return '正在提取成绩（共 $count 个学期）……';
  }

  @override
  String noScoresForSemesters(int count) {
    return '未检测到成绩数据（学期数：$count）';
  }

  @override
  String importedScoreRecords(int count) {
    return '成功导入 $count 条成绩记录！';
  }

  @override
  String retrievingExamsAttempt(int attempt) {
    return '正在提取考试安排……（第 $attempt 次尝试）';
  }

  @override
  String daysInAdvanceValue(int days) {
    return '提前 $days 天';
  }

  @override
  String get retrievingExams => '正在提取考试安排……';

  @override
  String examReminderAt(int days, String time) {
    return '考试前 $days 天 $time 提醒';
  }

  @override
  String examDaysBefore(int days) {
    return '考试前 $days 天';
  }

  @override
  String lastImportedAt(String time) {
    return '上次导入成绩时间 $time';
  }

  @override
  String unevaluatedCoursesExcludedFromGpa(int count) {
    return '本学期有 $count 门课程未评教，不计入 GPA';
  }

  @override
  String creditsValue(String value) {
    return '学分：$value';
  }

  @override
  String semesterWeekPosition(String semester, int week, String weekday) {
    return '$semester · 第 $week 周 · $weekday';
  }

  @override
  String scheduleEventDate(
    int month,
    int day,
    String weekday,
    String startTime,
    String endTime,
  ) {
    return '$month月$day日 $weekday  $startTime-$endTime';
  }

  @override
  String courseScheduleLine(String weekday, String periods, String time) {
    return '$weekday $periods $time';
  }

  @override
  String examCopyText(String course, String time, String location) {
    return '$course\n时间：$time\n地点：$location';
  }

  @override
  String get courseDetails => '课程详情';

  @override
  String get courseCatalogDisclaimer => '该页面仅供参考，请以教务系统为准';

  @override
  String get semesterCourseCount => '本学期课程数量';

  @override
  String get semesterTotalCredits => '本学期总学分';

  @override
  String get courseCode => '课程代码';

  @override
  String get courseType => '课程类型';

  @override
  String get assessmentMethod => '考核方式';

  @override
  String get offeringDepartment => '开课部门';

  @override
  String get teachingFormat => '教学形式';

  @override
  String get totalClassHours => '总学时';

  @override
  String get teachingWeeks => '教学周数';

  @override
  String get classHourBreakdown => '学时组成';

  @override
  String get theoryHours => '理论';

  @override
  String get practiceHours => '实践';

  @override
  String get focusedPracticeHours => '集中实践';

  @override
  String get dispersedPracticeHours => '分散实践';

  @override
  String get assessmentHours => '考核';

  @override
  String get experimentHours => '实验';

  @override
  String get computerHours => '上机';

  @override
  String get designHours => '设计';

  @override
  String get extracurricularHours => '课外';

  @override
  String courseCreditValue(String value) {
    return '$value 学分';
  }

  @override
  String requiredField(String field) {
    return '请输入$field';
  }
}
