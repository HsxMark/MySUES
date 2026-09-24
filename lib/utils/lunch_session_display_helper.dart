import '../models/course.dart';
import '../services/schedule_service.dart';
import 'building_lunch_boundary.dart';

/// 课表显示层的午间分场处理（不改存储数据、不改解析逻辑）。
///
/// - 开关关（默认）：把导入时被拆成「上午场 + 下午场」的同一门课视觉合并成一块。
/// - 开关开：跨午长课拆成上/下午两张卡；已拆数据保持两场。
///
/// 合并展示项通过 [Course.displaySourceIds] 携带全部库内源 id，
/// 删除/导出/编辑必须对整组源记录生效，不能只操作上午半场。
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

  /// 展示项 → 库中源课程列表（合并卡可能对应上下两条）。
  static List<Course> resolveSources(Course display, List<Course> stored) {
    final ids = <int>{};
    if (display.displaySourceIds.isNotEmpty) {
      ids.addAll(display.displaySourceIds.where((id) => id != 0));
    } else if (display.id != 0) {
      ids.add(display.id);
    }
    if (ids.isEmpty) return [display];

    final result = <Course>[];
    for (final id in ids) {
      for (final c in stored) {
        if (c.id == id) {
          result.add(c);
          break;
        }
      }
    }
    return result.isEmpty ? [display] : result;
  }

  /// 单条源课程（详情文案等）；合并卡时取上午场。
  static Course resolveSource(Course display, List<Course> stored) {
    final list = resolveSources(display, stored);
    return list.isEmpty ? display : list.first;
  }

  /// 打开编辑器时使用的课程对象。
  /// - 单源（含分场展示副本）：库中完整课
  /// - 合并卡（多源）：保留合并后的节次范围，并携带全部源 id
  static Course courseForEditor(Course display, List<Course> stored) {
    final sources = resolveSources(display, stored);
    if (sources.length == 1) {
      return sources.first;
    }
    final editor = Course(
      id: sources.isEmpty ? display.id : sources.first.id,
      courseName: display.courseName,
      day: display.day,
      room: display.room,
      teacher: display.teacher,
      startNode: display.startNode,
      step: display.step,
      startWeek: display.startWeek,
      endWeek: display.endWeek,
      type: display.type,
      color: display.color,
      tableId: display.tableId,
      startTime: display.startTime,
      endTime: display.endTime,
      studyType: display.studyType,
      isHidden: display.isHidden,
    );
    editor.displaySourceIds = sources.map((s) => s.id).toList();
    return editor;
  }

  /// 删除展示项对应的全部库内课程（合并卡会删掉上、下午两条）。
  /// 一次写入，只触发一次小组件刷新。
  static Future<void> deleteDisplayCourse(
    Course display,
    List<Course> stored,
  ) async {
    final sources = resolveSources(display, stored);
    await ScheduleDataService.deleteCourses(sources.map((s) => s.id).toList());
  }

  /// 将编辑结果写回库。
  /// - 单源：update 原记录
  /// - 多源（合并半场）：一次事务内删旧半场并按新节次重写；
  ///   仍跨午则拆成两条，且 **按半场裁剪自定义时间**，避免整课时间写入两半。
  ///
  /// [sourceIds]：编辑器返回的 Course 可能已丢失展示层字段，
  /// 由调用方传入打开编辑前解析到的库内源 id。
  static Future<void> persistEditedCourse(
    Course edited,
    List<Course> stored, {
    List<int>? sourceIds,
  }) async {
    if (sourceIds != null && sourceIds.isNotEmpty) {
      edited.displaySourceIds = sourceIds.where((id) => id != 0).toList();
    }
    final sources = resolveSources(edited, stored);

    if (sources.length <= 1) {
      final id = sources.isEmpty ? edited.id : sources.first.id;
      if (id != 0) {
        edited.id = id;
        await ScheduleDataService.updateCourse(edited);
        return;
      }
      await ScheduleDataService.addCourse(edited);
      return;
    }

    final start = edited.startNode;
    final endNode = edited.startNode + edited.step - 1;
    const morningLast = BuildingLunchBoundary.morningLastNode;
    const afternoonFirst = BuildingLunchBoundary.afternoonFirstNode;

    final hasCustomTimes =
        (edited.startTime != null && edited.startTime!.isNotEmpty) ||
        (edited.endTime != null && edited.endTime!.isNotEmpty);

    Course make({
      required int startNode,
      required int step,
      String? startTime,
      String? endTime,
    }) {
      return Course(
        courseName: edited.courseName,
        day: edited.day,
        room: edited.room,
        teacher: edited.teacher,
        startNode: startNode,
        step: step,
        startWeek: edited.startWeek,
        endWeek: edited.endWeek,
        type: edited.type,
        color: edited.color,
        tableId: edited.tableId,
        startTime: startTime,
        endTime: endTime,
        studyType: edited.studyType,
        isHidden: edited.isHidden,
      );
    }

    final toAdd = <Course>[];

    if (BuildingLunchBoundary.crossesLunchByNodes(start, endNode)) {
      // 上午场：开始沿用整课 start；结束用该楼下课（勿把下午 end 写进上午）
      if (start <= morningLast) {
        toAdd.add(
          make(
            startNode: start,
            step: morningLast - start + 1,
            startTime: hasCustomTimes ? edited.startTime : null,
            endTime: hasCustomTimes
                ? BuildingLunchBoundary.morningEndForRoom(edited.room)
                : null,
          ),
        );
      }
      // 下午场：开始 13:20；结束沿用整课 end
      if (endNode >= afternoonFirst) {
        toAdd.add(
          make(
            startNode: afternoonFirst,
            step: endNode - afternoonFirst + 1,
            startTime: hasCustomTimes
                ? BuildingLunchBoundary.afternoonStart()
                : null,
            endTime: hasCustomTimes ? edited.endTime : null,
          ),
        );
      }
    } else {
      toAdd.add(
        make(
          startNode: start,
          step: edited.step,
          startTime: edited.startTime,
          endTime: edited.endTime,
        ),
      );
    }

    await ScheduleDataService.replaceCourses(
      removeIds: sources.map((s) => s.id).toList(),
      toAdd: toAdd,
    );
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
      final sourceIds = [if (c.id != 0) c.id];

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
            displaySourceIds: sourceIds,
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
            displaySourceIds: sourceIds,
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
      displaySourceIds: [
        if (morning.id != 0) morning.id,
        if (afternoon.id != 0) afternoon.id,
      ],
    );
  }

  static Course _copyCourse(
    Course source, {
    required int startNode,
    required int step,
    String? startTime,
    String? endTime,
    List<int> displaySourceIds = const [],
  }) {
    final copy = Course(
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
    copy.displaySourceIds = displaySourceIds;
    return copy;
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
