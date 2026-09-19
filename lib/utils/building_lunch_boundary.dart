/// 午休边界（显示层软分割用）
///
/// 楼宇上下课分类 **以原有 BuildingTimeOverride 为准**，不在这里另写一套教室正则，
/// 避免与课表时间显示不一致。
/// - 上午场结束 = 第 5 节 end（按教室，如 D/E/J303 为 12:20）
/// - 下午场开始 = 第 6 节，全校默认 13:20
library;

import 'building_time_override.dart';

class BuildingLunchBoundary {
  /// 上午最后一节
  static const int morningLastNode = 5;

  /// 下午第一节
  static const int afternoonFirstNode = 6;

  /// 该教室上午场下课时间（与 BuildingTimeOverride 第5节 end 一致）
  static String morningEndForRoom(String room) {
    return BuildingTimeOverride.getOverrideEndTime(room, morningLastNode) ??
        '12:00';
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
