// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '苏伊士';

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
  String get welcomeAgreement => '欢迎使用苏伊士（My SUES）。在使用本应用前，请您仔细阅读并同意以下协议：';

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
}
