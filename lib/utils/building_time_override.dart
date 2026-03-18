






class BuildingTimeOverride {
  
  static final RegExp _dej303Pattern = RegExp(r'^[DE]|^J303');
  
  static final RegExp _afj301Pattern = RegExp(r'^[AF]|^J301');

  
  static String? getOverrideStartTime(String room, int node) {
    return _getMap(room)?[node]?['start'];
  }

  
  static String? getOverrideEndTime(String room, int node) {
    return _getMap(room)?[node]?['end'];
  }

  static Map<int, Map<String, String>>? _getMap(String room) {
    final r = room.trim();
    if (_dej303Pattern.hasMatch(r)) return _dej303Map;
    if (_afj301Pattern.hasMatch(r)) return _afj301Map;
    return _defaultMap;
  }

  
  static const Map<int, Map<String, String>> _dej303Map = {
    3: {'start': '10:15', 'end': '10:55'},
    4: {'start': '10:55', 'end': '11:35'},
    5: {'start': '11:40', 'end': '12:20'},
  };

  
  static const Map<int, Map<String, String>> _afj301Map = {
    3: {'start': '9:55', 'end': '10:35'},
    4: {'start': '10:40', 'end': '11:20'},
    5: {'start': '11:20', 'end': '12:00'},
  };

  
  static const Map<int, Map<String, String>> _defaultMap = {
    3: {'start': '9:55', 'end': '10:35'},
    4: {'start': '10:35', 'end': '11:15'},
    5: {'start': '11:20', 'end': '12:00'},
  };
}
