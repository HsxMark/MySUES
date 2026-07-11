/// 教学楼特殊上下课时间覆盖
///
/// 不同教学楼的第3-5节课时间不同，根据教室名称动态调整：
/// - D、E、J303：3-4节 10:15-11:35，5节 11:40-12:20
/// - A、F、J301：3节 9:55-10:35，4-5节 10:40-12:00
/// - B、C、J302 及其他：3-4节 9:55-11:15，5节 11:20-12:00
library;

class BuildingTimeOverride {
  /// D、E、J303
  static final RegExp _dej303Pattern = RegExp(r'^[DE]|^J303');
  /// A、F、J301
  static final RegExp _afj301Pattern = RegExp(r'^[AF]|^J301');

  /// 获取指定教室、节次的覆盖开始时间，若该节次无覆盖返回 null
  static String? getOverrideStartTime(String room, int node) {
    return _getMap(room)?[node]?['start'];
  }

  /// 获取指定教室、节次的覆盖结束时间，若该节次无覆盖返回 null
  static String? getOverrideEndTime(String room, int node) {
    return _getMap(room)?[node]?['end'];
  }

  static Map<int, Map<String, String>>? _getMap(String room) {
    final r = room.trim();
    if (_dej303Pattern.hasMatch(r)) return _dej303Map;
    if (_afj301Pattern.hasMatch(r)) return _afj301Map;
    return _defaultMap;
  }

  /// D、E、J303：3-4节 10:15-11:35，5节 11:40-12:20
  static const Map<int, Map<String, String>> _dej303Map = {
    3: {'start': '10:15', 'end': '10:55'},
    4: {'start': '10:55', 'end': '11:35'},
    5: {'start': '11:40', 'end': '12:20'},
  };

  /// A、F、J301：3节 9:55-10:35，4-5节 10:40-12:00
  static const Map<int, Map<String, String>> _afj301Map = {
    3: {'start': '9:55', 'end': '10:35'},
    4: {'start': '10:40', 'end': '11:20'},
    5: {'start': '11:20', 'end': '12:00'},
  };

  /// B、C、J302 及其他所有教学楼：3-4节 9:55-11:15，5节 11:20-12:00
  static const Map<int, Map<String, String>> _defaultMap = {
    3: {'start': '9:55', 'end': '10:35'},
    4: {'start': '10:35', 'end': '11:15'},
    5: {'start': '11:20', 'end': '12:00'},
  };
}
