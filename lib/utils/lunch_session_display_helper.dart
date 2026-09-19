import '../models/course.dart';
import 'building_lunch_boundary.dart';

/// 课表显示层的午间分场处理（不改存储数据、不改解析逻辑）。
///
/// - 开关关（默认）：把导入时被拆成「上午场 + 下午场」的同一门课视觉合并成一块。
/// - 开关开：跨午长课拆成上/下午两张卡；已拆数据保持两场。
class LunchSessionDisplayHelper {
  /// 为周课表准备展示用课程列表。
  static List<Course> prepareForDisplay(
    List<Course> courses, {
    required bool splitLunch,
  }) {
    if (splitLunch) {
      return _splitCrossingLunch(courses);
    }
    return _mergeLunchHalves(courses);
  }

  /// 是否跨午（节次法；有自定义起止时间时用时间法）
  static bool crossesLunch(Course course) {
    final endNode = course.startNode + course.step - 1;
    if (BuildingLunchBoundary.crossesLunchByNodes(course.startNode, endNode)) {
      return true;
    }
    final start = _parseMinutes(course.startTime);
    final end = _parseMinutes(course.endTime);
    if (start == null || end == null) return false;
    final morningEnd = _parseMinutes(
      BuildingLunchBoundary.morningEndForRoom(course.room),
    )!;
    final afternoonStart = _parseMinutes(
      BuildingLunchBoundary.afternoonStart(),
    )!;
    return start < morningEnd && end > afternoonStart;
  }

  /// 开关开：把跨午课程拆成上午场 + 下午场（仅展示副本）
  static List<Course> _splitCrossingLunch(List<Course> courses) {
    final result = <Course>[];
    for (final c in courses) {
      if (!crossesLunch(c)) {
        result.add(c);
        continue;
      }

      final endNode = c.startNode + c.step - 1;
      const morningLast = BuildingLunchBoundary.morningLastNode;
      const afternoonFirst = BuildingLunchBoundary.afternoonFirstNode;

      // 按节次裁剪，避免「时间跨午但节次未跨」时错误扩格
      final morningStart = c.startNode;
      final morningEnd = endNode < morningLast ? endNode : morningLast;
      final afternoonStart =
          c.startNode > afternoonFirst ? c.startNode : afternoonFirst;
      final afternoonEnd = endNode;

      final hasCustomTimes =
          (c.startTime != null && c.startTime!.isNotEmpty) ||
          (c.endTime != null && c.endTime!.isNotEmpty);
      final cutsAtLunchEnd = endNode > morningLast;
      final cutsAtLunchStart = c.startNode < afternoonFirst;

      var added = false;

      if (morningStart <= morningLast && morningStart <= morningEnd) {
        result.add(
          _copyCourse(
            c,
            startNode: morningStart,
            step: morningEnd - morningStart + 1,
            startTime: c.startTime,
            endTime: hasCustomTimes && cutsAtLunchEnd
                ? BuildingLunchBoundary.morningEndForRoom(c.room)
                : c.endTime,
          ),
        );
        added = true;
      }

      if (afternoonEnd >= afternoonFirst && afternoonStart <= afternoonEnd) {
        result.add(
          _copyCourse(
            c,
            startNode: afternoonStart,
            step: afternoonEnd - afternoonStart + 1,
            startTime: hasCustomTimes && cutsAtLunchStart
                ? BuildingLunchBoundary.afternoonStart()
                : c.startTime,
            endTime: c.endTime,
          ),
        );
        added = true;
      }

      if (!added) {
        result.add(c);
      }
    }
    return result;
  }

  /// 开关关：将「上午场结束于第5节 + 下午场从第6节开始」的同门课合并为一块
  ///
  /// 两趟扫描：先配对再补未匹配项，避免存储顺序为「下午在前、上午在后」时漏合并。
  static List<Course> _mergeLunchHalves(List<Course> courses) {
    final result = <Course>[];
    final used = <int>{};

    for (int i = 0; i < courses.length; i++) {
      if (used.contains(i)) continue;
      final morning = courses[i];
      final morningEnd = morning.startNode + morning.step - 1;
      if (morningEnd != BuildingLunchBoundary.morningLastNode) continue;

      for (int j = 0; j < courses.length; j++) {
        if (j == i || used.contains(j)) continue;
        final afternoon = courses[j];
        if (afternoon.startNode != BuildingLunchBoundary.afternoonFirstNode) {
          continue;
        }
        if (!_sameCourseIdentity(morning, afternoon)) continue;
        used.add(i);
        used.add(j);
        result.add(_mergePair(morning, afternoon));
        break;
      }
    }

    for (int i = 0; i < courses.length; i++) {
      if (!used.contains(i)) result.add(courses[i]);
    }
    return result;
  }

  static bool _sameCourseIdentity(Course a, Course b) {
    return a.day == b.day &&
        a.courseName == b.courseName &&
        a.room == b.room &&
        a.teacher == b.teacher &&
        a.startWeek == b.startWeek &&
        a.endWeek == b.endWeek &&
        a.type == b.type &&
        a.tableId == b.tableId &&
        a.isHidden == b.isHidden &&
        a.studyType == b.studyType;
  }

  static Course _mergePair(Course morning, Course afternoon) {
    final startNode = mathMin(morning.startNode, afternoon.startNode);
    final endNode = mathMax(
      morning.startNode + morning.step - 1,
      afternoon.startNode + afternoon.step - 1,
    );
    String? startTime;
    String? endTime;
    final mStart = _parseMinutes(morning.startTime);
    final aEnd = _parseMinutes(afternoon.endTime);
    if (mStart != null && aEnd != null) {
      startTime = morning.startTime;
      endTime = afternoon.endTime;
    }
    return _copyCourse(
      morning,
      startNode: startNode,
      step: endNode - startNode + 1,
      startTime: startTime,
      endTime: endTime,
    );
  }

  static Course _copyCourse(
    Course source, {
    required int startNode,
    required int step,
    String? startTime,
    String? endTime,
  }) {
    return Course(
      id: source.id,
      courseName: source.courseName,
      day: source.day,
      room: source.room,
      teacher: source.teacher,
      startNode: startNode,
      step: step,
      startWeek: source.startWeek,
      endWeek: source.endWeek,
      type: source.type,
      color: source.color,
      tableId: source.tableId,
      startTime: startTime,
      endTime: endTime,
      studyType: source.studyType,
      isHidden: source.isHidden,
    );
  }

  static int? _parseMinutes(String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static int mathMin(int a, int b) => a < b ? a : b;
  static int mathMax(int a, int b) => a > b ? a : b;
}
