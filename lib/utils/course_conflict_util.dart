import '../models/course.dart';

class CourseConflictUtil {
  /// Detect overlapping courses in a given list of courses.
  /// Returns a map where each key is a unique day and slot description,
  /// and the value is a list of courses that overlap at that time.
  static Map<String, List<Course>> getConflictGroups(List<Course> courses) {
    Map<String, List<Course>> conflictGroups = {};

    // Check every pair of courses
    for (int i = 0; i < courses.length; i++) {
      for (int j = i + 1; j < courses.length; j++) {
        var c1 = courses[i];
        var c2 = courses[j];

        if (_isConflict(c1, c2)) {
          // Find a way to grouping them
          String key = '${c1.day}_${c1.startNode}_${c1.step}';

          if (!conflictGroups.containsKey(key)) {
            conflictGroups[key] = [c1];
          }
          if (!conflictGroups[key]!.contains(c2)) {
            conflictGroups[key]!.add(c2);
          }
        }
      }
    }

    return conflictGroups;
  }

  /// Check if two courses conflict (same week, same day, overlapping time)
  static bool _isConflict(Course c1, Course c2) {
    // Optimization: Check day first
    if (c1.day != c2.day) return false;

    // Check week intersection
    bool hasWeekIntersection = false;
    for (int w = 1; w <= 30; w++) {
      if (c1.inWeek(w) && c2.inWeek(w)) {
        hasWeekIntersection = true;
        break;
      }
    }
    if (!hasWeekIntersection) return false;

    // Node intersection
    int c1End = c1.startNode + c1.step - 1;
    int c2End = c2.startNode + c2.step - 1;

    bool nodeConflict = c1.startNode <= c2End && c2.startNode <= c1End;

    // Time intersection (minute-level precision if available)
    bool timeConflict = false;
    if (c1.startTime != null &&
        c1.endTime != null &&
        c2.startTime != null &&
        c2.endTime != null) {
      if (_timeToMinutes(c1.startTime!) < _timeToMinutes(c2.endTime!) &&
          _timeToMinutes(c2.startTime!) < _timeToMinutes(c1.endTime!)) {
        timeConflict = true;
      }
    } else {
      timeConflict = nodeConflict;
    }

    return nodeConflict || timeConflict;
  }

  static int _timeToMinutes(String time) {
    var parts = time.split(':');
    if (parts.length == 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    return 0;
  }
}
