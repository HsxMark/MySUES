import 'package:flutter/material.dart';

/// Compatibility wrapper used while legacy screens are migrated to generated
/// ARB getters. It keeps the original Chinese source as the stable lookup key.
class LText extends StatelessWidget {
  const LText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) => Text(
    legacyTranslate(context, data),
    style: style,
    strutStyle: strutStyle,
    textAlign: textAlign,
    textDirection: textDirection,
    locale: locale,
    softWrap: softWrap,
    overflow: overflow,
    textScaler: textScaler,
    maxLines: maxLines,
    semanticsLabel: semanticsLabel,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    selectionColor: selectionColor,
  );
}

String legacyTranslate(BuildContext context, String source) {
  if (Localizations.localeOf(context).languageCode == 'zh') return source;
  final exact = _english[source];
  if (exact != null) return exact;

  var result = source;
  result = result.replaceAllMapped(
    RegExp(r'第\s*(\d+)\s*周'),
    (match) => 'Week ${match.group(1)}',
  );
  result = result.replaceAllMapped(
    RegExp(r'第\s*(\d+)\s*-\s*(\d+)\s*周'),
    (match) => 'Weeks ${match.group(1)}–${match.group(2)}',
  );
  result = result.replaceAllMapped(
    RegExp(r'第\s*(\d+)\s*节'),
    (match) => 'Period ${match.group(1)}',
  );
  result = result.replaceAllMapped(
    RegExp(r'^学期\s+(.+)$'),
    (match) => 'Semester ${match.group(1)}',
  );
  result = result.replaceAllMapped(
    RegExp(r'^提前\s*(\d+)\s*天$'),
    (match) => '${match.group(1)} days in advance',
  );
  result = result.replaceAllMapped(
    RegExp(r'^考试前\s*(\d+)\s*天(?:\s*(.+?)\s*提醒)?$'),
    (match) => match.group(2) == null
        ? '${match.group(1)} days before the exam'
        : '${match.group(1)} days before the exam at ${match.group(2)}',
  );
  result = result.replaceAllMapped(
    RegExp(r'^周次\s*\(1-(\d+)\)$'),
    (match) => 'Week (1–${match.group(1)})',
  );
  result = result.replaceAllMapped(
    RegExp(r'^开学:\s*(.+)$'),
    (match) => 'Starts: ${match.group(1)}',
  );
  result = result.replaceAllMapped(
    RegExp(r'^(导入失败|导出失败|处理失败|提取失败|发生错误):\s*(.+)$'),
    (match) =>
        '${switch (match.group(1)) {
          '导入失败' => 'Import failed',
          '导出失败' => 'Export failed',
          '提取失败' => 'Extraction failed',
          '发生错误' => 'Error',
          _ => 'Processing failed',
        }}: ${match.group(2)}',
  );
  result = result.replaceAllMapped(
    RegExp(r'^周次超出范围，请输入\s*1-(\d+)$'),
    (match) => 'Week out of range. Enter 1–${match.group(1)}.',
  );
  result = result.replaceAllMapped(
    RegExp(r'^头像上传失败:\s*(.+)$'),
    (match) => 'Failed to upload avatar: ${match.group(1)}',
  );
  result = result.replaceAllMapped(
    RegExp(r'^由\s*(.+)\s*提供$'),
    (match) => 'Provided by ${match.group(1)}',
  );
  result = result.replaceAllMapped(
    RegExp(r'^请输入(.+)$'),
    (match) => 'Enter ${legacyTranslate(context, match.group(1)!)}',
  );
  result = result.replaceAllMapped(
    RegExp(r'^学分:\s*(.+)$'),
    (match) => 'Credits: ${match.group(1)}',
  );
  result = result.replaceAllMapped(
    RegExp(r'^本学期有\s*(\d+)\s*门课程未评教，不计入GPA$'),
    (match) => '${match.group(1)} pending · excluded from GPA',
  );
  result = result.replaceAllMapped(
    RegExp(r'^上次导入成绩时间(.+)$'),
    (match) => 'Imported ${match.group(1)}',
  );
  result = result.replaceAllMapped(
    RegExp(r'^正在提取考试安排\.\.\.(?:\s*\(第(\d+)次尝试\))?$'),
    (match) => match.group(1) == null
        ? 'Retrieving exams…'
        : 'Retrieving exams… (attempt ${match.group(1)})',
  );
  result = result.replaceAllMapped(
    RegExp(r'^确认要删除\s*"(.+)"\s*吗？$'),
    (match) => 'Delete “${match.group(1)}”?',
  );
  result = result.replaceAllMapped(
    RegExp(r'^确认要删除课程\s*"(.+)"\s*吗？$'),
    (match) => 'Delete course “${match.group(1)}”?',
  );
  result = result.replaceAllMapped(
    RegExp(r'^确认要删除课表\s*"(.+)"\s*吗？\n删除后该课表下的所有课程也会被清空。$'),
    (match) =>
        'Delete schedule “${match.group(1)}”?\nAll courses in it will also be deleted.',
  );
  result = result.replaceAllMapped(
    RegExp(r'^周([一二三四五六日])\s+第(\d+)\s*-\s*(\d+)节\s*(.*)$'),
    (match) =>
        '${_englishWeekday(match.group(1)!)} · Periods ${match.group(2)}–${match.group(3)} ${match.group(4)}'
            .trim(),
  );
  result = result.replaceAllMapped(
    RegExp(r'^(.+)\n周([一二三四五六日])\s+第(\d+)\s*-\s*(\d+)节\s*(.*)\n(.*)$'),
    (match) =>
        '${match.group(1)}\n${_englishWeekday(match.group(2)!)} · Periods ${match.group(3)}–${match.group(4)} ${match.group(5)}\n${match.group(6)}',
  );
  result = result.replaceAllMapped(
    RegExp(r'^(.+)\n时间:\s*(.+)\n地点:\s*(.*)$'),
    (match) =>
        '${match.group(1)}\nTime: ${match.group(2)}\nLocation: ${match.group(3)}',
  );
  result = result.replaceAllMapped(
    RegExp(r'^•\s*(.+)\s*\(星期([1-7])\s+第(\d+)-(\d+)节\)$'),
    (match) =>
        '• ${match.group(1)} (${_englishWeekdayNumber(match.group(2)!)} · Periods ${match.group(3)}–${match.group(4)})',
  );
  return result;
}

String _englishWeekday(String chinese) => switch (chinese) {
  '一' => 'Monday',
  '二' => 'Tuesday',
  '三' => 'Wednesday',
  '四' => 'Thursday',
  '五' => 'Friday',
  '六' => 'Saturday',
  _ => 'Sunday',
};

String _englishWeekdayNumber(String number) =>
    _englishWeekday(['一', '二', '三', '四', '五', '六', '日'][int.parse(number) - 1]);

String localizedMonthTitle(BuildContext context, DateTime date) {
  if (Localizations.localeOf(context).languageCode == 'zh') {
    return '${date.month}月';
  }
  return _englishMonths[date.month - 1];
}

String localizedCompactMonth(BuildContext context, DateTime date) {
  if (Localizations.localeOf(context).languageCode == 'zh') {
    return '${date.month}\n月';
  }
  return _englishMonthsShort[date.month - 1];
}

String localizedScheduleEventDate(
  BuildContext context,
  DateTime date,
  String startTime,
  String endTime,
) {
  if (Localizations.localeOf(context).languageCode == 'zh') {
    final weekday = [
      '周一',
      '周二',
      '周三',
      '周四',
      '周五',
      '周六',
      '周日',
    ][date.weekday - 1];
    return '${date.month}月${date.day}日 $weekday  $startTime-$endTime';
  }
  return '${_englishMonthsShort[date.month - 1]} ${date.day}, ${_englishWeekdaysShort[date.weekday - 1]}  $startTime-$endTime';
}

String localizedSemesterPosition(
  BuildContext context,
  String semester,
  int week,
  DateTime date,
) {
  final translatedSemester = legacyTranslate(context, semester);
  if (Localizations.localeOf(context).languageCode == 'zh') {
    return '$translatedSemester · 第 $week 周 周${['一', '二', '三', '四', '五', '六', '日'][date.weekday - 1]}';
  }
  return '$translatedSemester · Week $week · ${_englishWeekdays[date.weekday - 1]}';
}

const _englishMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _englishMonthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _englishWeekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _englishWeekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const Map<String, String> _english = {
  '一': 'Mon',
  '二': 'Tue',
  '三': 'Wed',
  '四': 'Thu',
  '五': 'Fri',
  '六': 'Sat',
  '日': 'Sun',
  '周一': 'Mon',
  '周二': 'Tue',
  '周三': 'Wed',
  '周四': 'Thu',
  '周五': 'Fri',
  '周六': 'Sat',
  '周日': 'Sun',
  '默认课表': 'Default Schedule',
  '苏伊士': 'My SUES',
  '苏伊士 by HsxMark': 'My SUES by HsxMark',
  '我的课表': 'My Schedule',
  '我': 'Profile',
  '[免听]': '[Attendance Exempt]',
  '[重修]': '[Retake]',
  '[非本周]': '[Outside This Week]',
  '(肆年制)': '(Four-year Program)',
  '保存': 'Save',
  '取消': 'Cancel',
  '确认': 'Confirm',
  '确定': 'OK',
  '删除': 'Delete',
  '编辑': 'Edit',
  '关闭': 'Close',
  '跳过': 'Skip',
  '下一步': 'Next',
  '跳转': 'Go',
  '全部': 'All',
  '无数据': 'No data',
  '未设置': 'Not set',
  '已设置': 'Set',
  '未选择': 'Not selected',
  '未知': 'Unknown',
  '未知学期': 'Unknown Semester',
  '登录': 'Sign In',
  '教务系统': 'Academic System',
  '请登录您的账号': 'Sign in to your account',
  '登录成功，请点击下方按钮提取数据': 'Signed in. Use the buttons below to retrieve your data.',
  'WebVPN 网页提取': 'WebVPN Data Import',
  '清理缓存': 'Clear Cache',
  '缓存已清理': 'Cache cleared',
  '请选择要提取的内容': 'Choose the data to retrieve',
  '请选择导入学期': 'Choose a semester to import',
  '提取菜单': 'Import Menu',
  '提取个人信息': 'Retrieve Profile',
  '提取课表': 'Retrieve Schedule',
  '提取成绩': 'Retrieve Grades',
  '提取考试安排': 'Retrieve Exams',
  '提取失败，请重试': 'Extraction failed. Try again.',
  '抓取失败，请重试': 'Request failed. Try again.',
  '抓取课表数据失败': 'Failed to retrieve schedule data',
  '跳转到课表页面以获取数据...': 'Opening the schedule page to retrieve data…',
  '正在等待页面加载...': 'Waiting for the page to load…',
  '正在跳转到教务系统...': 'Opening the academic system…',
  '正在跳转到课表页面...': 'Opening the schedule page…',
  '正在获取基础数据...': 'Retrieving basic data…',
  '正在获取学期列表...': 'Retrieving semesters…',
  '正在解析...': 'Parsing…',
  '正在解析学生信息...': 'Parsing student information…',
  '正在提取个人信息...': 'Retrieving profile…',
  '正在保存课程数据...': 'Saving course data…',
  '页面加载超时，请重试': 'Page loading timed out. Try again.',
  '页面未就绪，请重试': 'The page is not ready. Try again.',
  '未获取到数据，等待重试...': 'No data received. Waiting to retry…',
  '未检测到个人信息': 'No profile information was found',
  '未检测到考试数据': 'No exam data was found',
  '未找到考试数据': 'No exam data was found',
  '未找到学期列表，请重试': 'No semester list was found. Try again.',
  '未能解析出任何课程': 'No courses could be parsed',
  '未能提取到有效的个人信息': 'No valid profile information could be extracted',
  '无法从课表数据中解析...': 'Unable to parse the schedule data…',
  '无法获取学期列表，请重试': 'Unable to retrieve semesters. Try again.',
  '无法获取学生信息，请重试': 'Unable to retrieve student information. Try again.',
  '获取学生信息失败': 'Failed to retrieve student information',
  '用户取消操作': 'Operation cancelled',
  '设置': 'Settings',
  '通知': 'Notifications',
  '界面与显示': 'Appearance & Display',
  '外观': 'Appearance',
  '浅色': 'Light',
  '深色': 'Dark',
  '跟随系统': 'Follow System',
  '浅色模式': 'Light Mode',
  '深色模式': 'Dark Mode',
  '系统默认': 'System Default',
  '字体': 'Font',
  '字体样式': 'Font Style',
  '字体资源': 'Font Resources',
  '设置背景图片': 'Set Background Image',
  '背景透明度': 'Background Opacity',
  '开屏动画': 'Splash Animation',
  '启动应用时显示开屏动画': 'Show the splash animation when the app starts',
  '实验性功能': 'Experimental Features',
  '液态玻璃效果 (BETA)': 'Liquid Glass Effect (BETA)',
  '开启后界面将呈现磨砂玻璃质感': 'Adds a frosted-glass appearance to the interface',
  '个人资料': 'Profile',
  '昵称': 'Nickname',
  '学号': 'Student ID',
  '姓名': 'Name',
  '专业': 'Major',
  '学院': 'College',
  '班级': 'Class',
  '年级': 'Year',
  '修改昵称': 'Change Nickname',
  '修改专业': 'Change Major',
  '修改学院': 'Change College',
  '修改班级': 'Change Class',
  '头像': 'Avatar',
  '上次同步时间': 'Last Sync',
  '请连接教务系统同步身份信息': 'Connect to the academic system to sync your profile',
  '教务连接': 'Academic System',
  '已连接': 'Connected',
  '未连接': 'Not Connected',
  '点击同步数据': 'Tap to Sync Data',
  '请登录 教务系统': 'Sign in to the Academic System',
  '进入 苏伊士': 'Enter My SUES',
  '欢迎使用苏伊士 My SUES': 'Welcome to My SUES',
  '一站式校园信息助手，让你的校园生活更便捷。':
      'Your all-in-one campus assistant for a simpler university life.',
  '快速查看每周或每日课程安排，支持导入教务系统课表。':
      'View weekly or daily classes and import schedules from the academic system.',
  '随时查看各科成绩与绩点，掌握学业情况。': 'Review grades and GPA whenever you need them.',
  '及时获取考试时间与地点，不错过每场考试。': 'Keep track of exam times and locations.',
  '查看课表': 'View Schedule',
  '查看个人成绩': 'View Grades',
  '查看考试信息': 'View Exams',
  '课程表': 'Schedule',
  '每日课表': 'Daily Schedule',
  '课表设置': 'Schedule Settings',
  '课表显示设置': 'Schedule Display',
  '课表名称': 'Schedule Name',
  '新课表': 'New Schedule',
  '新建课表': 'New Schedule',
  '切换课表': 'Switch Schedule',
  '删除课表': 'Delete Schedule',
  '长按删除课表': 'Press and hold to delete a schedule',
  '没有课表数据，请先创建课表': 'No schedule found. Create one first.',
  '同步考试': 'Sync Exam',
  '同步课表': 'Sync Schedule',
  '同步成绩': 'Sync Grades',
  '取消导入': 'Cancel Import',
  '已取消导入': 'Import cancelled',
  '导出 ICS': 'Export ICS',
  '导出课表 (.ics)': 'Export Schedule (.ics)',
  '导出课表(.ics)': 'Export Schedule (.ics)',
  '当前没有课程可以导出': 'There are no courses to export',
  '课程': 'Course',
  '课程名称': 'Course Name',
  '老师': 'Instructor',
  '教室': 'Room',
  '地点': 'Location',
  '星期': 'Weekday',
  '开始周': 'Start Week',
  '结束周': 'End Week',
  '开始节次': 'Start Period',
  '结束节次': 'End Period',
  '开始时间': 'Start Time',
  '结束时间': 'End Time',
  '开始时间(HH:mm)': 'Start Time (HH:mm)',
  '结束时间(HH:mm)': 'End Time (HH:mm)',
  '单双周': 'Week Pattern',
  '每周': 'Every Week',
  '单周': 'Odd Weeks',
  '双周': 'Even Weeks',
  '课程颜色': 'Course Color',
  '修读状态': 'Study Status',
  '正常修读': 'Normal',
  '重修': 'Retake',
  '免听': 'Attendance Exempt',
  '编辑课程': 'Edit Course',
  '添加课程': 'Add Course',
  '删除课程': 'Delete Course',
  '复制课程名称': 'Copy Course Name',
  '复制课程信息为文本': 'Copy Course Details as Text',
  '已复制课程名称': 'Course name copied',
  '已复制课程信息': 'Course details copied',
  '注意：存在课程冲突': 'Warning: Course Conflict',
  '您有以下课程在同一时间段产生冲突：': 'The following courses overlap:',
  '是否继续保存？您可以在课表中正常查看它们，或后续修改免听/重修状态。':
      'Save anyway? You can view them in the schedule or adjust their study status later.',
  '继续保存': 'Save Anyway',
  '是否在课表中隐藏？': 'Hide this course from the schedule?',
  '隐藏后将不会在课表视图中显示该课程': 'Hidden courses are not shown in the schedule view',
  '成绩单': 'Grades',
  '绩点': 'GPA',
  '学分': 'Credits',
  '修读学分': 'Credits',
  '学期 GPA': 'Semester GPA',
  '学期详情': 'Semester',
  '总平均绩点 (GPA)': 'Overall GPA',
  '课程 学分...': 'Course  Credits…',
  '未评教': 'Pending',
  '暂无成绩数据，点击右上方按钮进行导入': 'No grades yet. Import them from the menu.',
  '导入成绩单': 'Import Transcript',
  '成绩说明': 'Grade Information',
  '清空成绩': 'Clear Grades',
  '确认清空': 'Clear',
  '挂科': 'Failed',
  '缓考': 'Deferred',
  '考试信息': 'Exam Information',
  '考试提醒': 'Exam Reminders',
  '考试安排导入成功': 'Exam schedule imported',
  '添加考试': 'Add Exam',
  '编辑考试': 'Edit Exam',
  '保存考试信息': 'Save Exam',
  '考试信息非即时获取，仅供参考，请以教务处系统提示为准！':
      'Exam information may not be current. Always confirm it in the official academic system.',
  '暂无符合条件的考试信息': 'No matching exams',
  '清除已结束': 'Clear Finished',
  '已清除所有已结束的考试': 'All finished exams were cleared',
  '今日考试，请注意时间！': 'Exam today — check the time carefully!',
  '复制考试名称': 'Copy Exam Name',
  '复制考试信息为文本': 'Copy Exam Details as Text',
  '已复制考试名称': 'Exam name copied',
  '已复制考试信息': 'Exam details copied',
  '时间': 'Time',
  '类型': 'Type',
  '当前状态': 'Status',
  '未开始': 'Not Started',
  '未结束': 'Upcoming',
  '进行中': 'In Progress',
  '已结束': 'Finished',
  '期中': 'Midterm',
  '期末': 'Final',
  '补考': 'Make-up Exam',
  '课程提醒': 'Class Reminders',
  '上课前15分钟提醒': 'Remind me 15 minutes before class',
  '需要通知权限才能设置课程提醒': 'Notification permission is required for class reminders',
  '需要通知权限才能设置考试提醒': 'Notification permission is required for exam reminders',
  '已开启课程提醒': 'Class reminders enabled',
  '已关闭课程提醒': 'Class reminders disabled',
  '已开启考试提醒': 'Exam reminders enabled',
  '已关闭考试提醒': 'Exam reminders disabled',
  '提前几天提醒': 'Days Before',
  '提前天数': 'Days in Advance',
  '提醒时间': 'Reminder Time',
  '选择提醒时间': 'Choose Reminder Time',
  '开启后可自定义提醒时间': 'Enable to choose a custom reminder time',
  '关于': 'About',
  '项目信息': 'Project Information',
  '使用教程': 'Tutorial',
  '检查更新': 'Check for Updates',
  '开源信息': 'Open Source',
  '免责声明': 'Disclaimer',
  '本功能仅提供便捷的信息同步服务，导入的数据可能存在偏差。请仔细核对同步后的信息，一切以教务处网站显示为准。':
      'This feature provides a convenient way to sync information, but imported data may contain errors. Review the results carefully and rely on the official academic system.',
  '不再显示': 'Do not show again',
  '我已知悉': 'I Understand',
  '处理中...': 'Processing…',
  '用户协议': 'User Agreement',
  '隐私政策': 'Privacy Policy',
  '鸣谢': 'Acknowledgements',
  '赞助者': 'Sponsors',
  '作者': 'Author',
  '独立开发者': 'Independent Developer',
  '欢迎参与贡献或进行 bug 反馈': 'Contributions and bug reports are welcome',
  '桌面小组件': 'Home Screen Widget',
  '将课表添加到桌面，无需打开应用即可查看。':
      'Add your schedule to the home screen for quick access.',
  '大学进度': 'Degree Progress',
  '本学期进度': 'Semester Progress',
  '日程': 'Timeline',
  '今天': 'Today',
  '今天暂无课程': 'No classes today',
  '暂无即将发生课程': 'No upcoming classes',
  '即将发生': 'Upcoming',
  '快速跳转周次/日期': 'Jump to a Week or Date',
  '跳转到周次': 'Go to Week',
  '跳转到指定周': 'Go to a Specific Week',
  '回到当前周': 'Return to Current Week',
  '切换到日视图': 'Switch to Day View',
  '切换到周视图': 'Switch to Week View',
  '周次设置': 'Week Settings',
  '每天节数': 'Periods per Day',
  '学期周数': 'Semester Weeks',
  '开学日期': 'Semester Start Date',
  '显示周六': 'Show Saturday',
  '显示周日': 'Show Sunday',
  '显示非本周课程': 'Show Courses from Other Weeks',
  '显示课程时间': 'Show Course Times',
  '显示悬浮跳转按钮': 'Show Floating Jump Button',
  '显示已隐藏免听课程': 'Show Hidden Attendance-Exempt Courses',
  '开启后在课表视图中显示已隐藏的免听课程':
      'Show hidden attendance-exempt courses in the schedule',
  '高级设置': 'Advanced Settings',
  '节假日调休': 'Holiday Schedule Adjustments',
  '调休设置': 'Schedule Adjustment',
  '指定日期课程调换': 'Move Classes Between Dates',
  '选择被调课程日期': 'Choose Source Date',
  '选择目标上课日期': 'Choose Target Date',
  '日期A': 'Date A',
  '日期B': 'Date B',
  '确认调休': 'Confirm Adjustment',
  '调休处理完成': 'Schedule adjustment completed',
  '两个日期不能是同一天': 'The dates must be different',
  '请先选择需要调整的日期': 'Choose both dates first',
  '详情': 'Details',
  '菜单': 'Menu',
  '已复制': 'Copied',
  '确认删除': 'Confirm Deletion',
  '删除后无法恢复，是否继续？': 'This cannot be undone. Continue?',
  '单场考试时长不能超过24小时': 'An exam cannot last longer than 24 hours',
  '结束时间不能早于开始时间': 'The end time cannot be earlier than the start time',
  '课表名称不能为空': 'Schedule name cannot be empty',
  '课表名称已存在，请使用其他名称': 'That schedule name already exists. Choose another name.',
  '每天节数不能少于 10 节': 'There must be at least 10 periods per day',
  '学期周数不能少于 15 周': 'A semester must contain at least 15 weeks',
  '请输入有效的周次数字': 'Enter a valid week number',
  '请输入昵称': 'Enter a nickname',
  '请输入专业名称': 'Enter a major',
  '请输入学院名称': 'Enter a college',
  '请输入班级名称': 'Enter a class name',
  '请输入课程名称': 'Enter a course name',
  '请输入或选择类型': 'Enter or choose a type',
  '请选择开始时间': 'Choose a start time',
  '请选择结束时间': 'Choose an end time',
  '请完善开始和结束时间': 'Enter both a start and end time',
  '确定要清空所有成绩数据吗？此操作不可撤销。': 'Clear all grade data? This cannot be undone.',
  '以下内容可长按复制': 'Press and hold to copy the content below',
  '筛选: ': 'Filter: ',
  '上课时间': 'Class Time',
  '衷心感谢以下用户对本项目的赞助（排名不分先后）':
      'Sincere thanks to the following sponsors, listed in no particular order.',
  '若遇到什么问题，请添加QQ群聊：1045770691 反馈问题': 'For support, join QQ group 1045770691.',
  '工程  管理  设计': 'Engineering  Management  Design',
  '免费商用': 'Free for Commercial Use',
  '留学生专用': 'For International Students',
  '遵循 HarmonyOS Sans 字体授权协议': 'Licensed under the HarmonyOS Sans Font License',
  '遵循 MiSans 字体知识产权许可协议': 'Licensed under the MiSans Font License',
  '节假日调休处理说明：\n该功能会将"日期A"的课程移动到"日期B"。移动逻辑为：\n1. 将日期A的课程剪切到日期B。\n2. 日期B该天的原有课程会被清空。\n3. 注意：仅对指定日期的单日课程生效，不影响整个学期的其他同安排课程。':
      'Holiday adjustment instructions:\nThis moves classes from Date A to Date B.\n1. Classes on Date A are moved to Date B.\n2. Existing classes on Date B are cleared.\n3. Only the selected dates are affected; recurring semester arrangements are unchanged.',
  '本应用提供的成绩计算及绩点统计功能仅供参考。\n\n由于学校教务系统可能会调整计算规则，或者存在特殊课程（如未评教、重修、免修、缓考等）的处理差异，本应用的计算结果可能与官方教务系统存在细微偏差。\n\n请最终以教务系统发布的正式成绩单为准，开发者不对因使用本数据造成的任何问题承担责任。':
      'Grade and GPA calculations in this app are for reference only.\n\nUniversity rules and special cases such as unevaluated, repeated, exempted, or deferred courses may differ from these calculations.\n\nAlways rely on the official transcript.',
};
