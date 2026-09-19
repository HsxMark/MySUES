/// 午休边界（独立副本，不修改 BuildingTimeOverride）
///
/// 仅用于课表「午间分场」显示：判断上午场结束 / 下午场开始。
/// 作息对照教务课表：
/// - A/F/J301：上午结束 12:00
/// - D/E/J303：上午结束 12:20
/// - B/C/J302 及其他：上午结束 12:00
/// - 下午第6节全体：13:20 起
library;

class BuildingLunchBoundary {
  /// 上午最后一节
  static const int morningLastNode = 5;

  /// 下午第一节
  static const int afternoonFirstNode = 6;

  /// 教室名 → 楼宇分组（独立正则，避免与 BuildingTimeOverride 耦合）
  static final RegExp _dej303Pattern = RegExp(
    r'教学楼[DE]|J303|^[DE]\d|楼[DE]\d|^[DE]楼',
  );
  static final RegExp _afj301Pattern = RegExp(
    r'教学楼[AF]|J301|^[AF]\d|楼[AF]\d|^[AF]楼',
  );

  /// 该教室上午场下课时间（第5节 end）；无法判断时返回默认 12:00
  static String morningEndForRoom(String room) {
    final r = room.trim();
    if (_dej303Pattern.hasMatch(r)) return '12:20';
    if (_afj301Pattern.hasMatch(r)) return '12:00';
    return '12:00';
  }

  /// 下午场开始时间（全校统一第6节 13:20）
  static String afternoonStart() => '13:20';

  /// 节次是否落在上午场
  static bool isMorningNode(int node) => node <= morningLastNode;

  /// 节次是否落在下午场
  static bool isAfternoonNode(int node) => node >= afternoonFirstNode;

  /// 节次区间是否跨过午休
  static bool crossesLunchByNodes(int startNode, int endNode) {
    return startNode <= morningLastNode && endNode >= afternoonFirstNode;
  }
}
