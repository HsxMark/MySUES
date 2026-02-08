import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/course.dart';

class FetchCourseService {
  static const String _vpnSuffix = "vpn-12-o2-jxfw.sues.edu.cn";

  /// Helper: Executes XHR request inside WebView
  static Future<String?> _fetchWithXhr(WebViewController controller, String url) async {
    try {
      final safeUrl = url.replaceAll("'", "\\'");
      final js = """
        (function() {
          try {
            var xhr = new XMLHttpRequest();
            xhr.open('GET', '$safeUrl', false);
            xhr.withCredentials = true; // Important for cookies
            xhr.setRequestHeader('Accept', 'application/json, text/plain, */*');
            xhr.send();
            if (xhr.status >= 200 && xhr.status < 300) {
               return xhr.responseText;
            } else {
               return 'JS_ERROR: HTTP ' + xhr.status + ' ' + xhr.statusText;
            }
          } catch(e) {
            return 'JS_ERROR: ' + e.toString();
          }
        })();
      """;

      final result = await controller.runJavaScriptReturningResult(js);
      String response = "";
      if (result is String) {
        // Remove quotes if they indicate a JSON string wrapping
        if (result.startsWith('"') && result.endsWith('"')) {
             try {
               response = jsonDecode(result);
             } catch(_) {
               response = result;
             }
        } else {
             response = result;
        }
      } else {
        response = result.toString();
      }

      if (response.startsWith("JS_ERROR:")) {
        debugPrint("WebView XHR Failed for $url: $response");
        return null;
      }
      return response;
    } catch (e) {
      debugPrint("WebView Eval Failed: $e");
      return null;
    }
  }

  /// 1. Extracts semester IDs from the page DOM
  static Future<List<String>> fetchSemesterIds(WebViewController controller) async {
    const js = """
      (function() {
        var select = document.getElementById('add-drop-take-semesters');
        if (!select) return [];
        var options = select.getElementsByTagName('option');
        var ids = [];
        for (var i = 0; i < options.length; i++) {
          var val = options[i].value;
          if (val && val !== 'all') {
            ids.push(val);
          }
        }
        return JSON.stringify(ids);
      })();
    """;
    
    try {
      final result = await controller.runJavaScriptReturningResult(js);
      String jsonStr = result.toString();
      // Unquote if necessary (sometimes runJavaScriptReturningResult returns "[\"234\"]")
      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
         try {
           jsonStr = jsonDecode(jsonStr); 
         } catch(_) {}
      }
      
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint("Error fetching semester IDs: $e");
      return [];
    }
  }

  /// 2. Fetches detailed info for a semester
  static Future<Map<String, dynamic>?> fetchSemesterInfo(
      WebViewController controller, String baseUrl, String semesterId) async {
    // URL pattern from python script:
    // f"{BASE_URL}/student/ws/semester/get/{semester_id}?{VPN_SUFFIX}"
    final url = "$baseUrl/student/ws/semester/get/$semesterId?$_vpnSuffix";
    
    final jsonStr = await _fetchWithXhr(controller, url);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error parsing semester info: $e");
      return null;
    }
  }

  /// 3. Fetches course table data
  static Future<Map<String, dynamic>?> fetchCourseData(
      WebViewController controller, String baseUrl, String semesterId) async {
    // URL pattern from python script:
    // f"{BASE_URL}/student/for-std/course-table/semester/{semester_id}/print-data?{VPN_SUFFIX}&semesterId={semester_id}&hasExperiment=true"
    final url = "$baseUrl/student/for-std/course-table/semester/$semesterId/print-data?$_vpnSuffix&semesterId=$semesterId&hasExperiment=true";
    
    final jsonStr = await _fetchWithXhr(controller, url);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error parsing course data: $e");
      return null;
    }
  }

  /// 4. Parses raw JSON into `Course` objects
  static List<Course> parseCourseData(Map<String, dynamic> json, int tableId) {
    if (!json.containsKey('studentTableVms')) return [];
    
    List<Course> courses = [];
    final vms = json['studentTableVms'] as List;
    if (vms.isEmpty) return [];

    // Usually there is only one student VM, but we iterate just in case
    for (var vm in vms) {
      final activities = vm['activities'] as List?;
      if (activities == null) continue;

      for (var activity in activities) {
        try {
          final courseName = activity['courseName']?.toString() ?? "未知课程";
          final room = activity['room']?.toString() ?? "";
          final teachers = (activity['teachers'] as List?)?.join(",") ?? "";
          final weekday =( activity['weekday'] as int? ?? 1);
          final startUnit = (activity['startUnit'] as int? ?? 1);
          final endUnit = (activity['endUnit'] as int? ?? 1);
          final step = endUnit - startUnit + 1;
          
          final weekIndexes = (activity['weekIndexes'] as List?)?.map((e) => e as int).toList() ?? [];
          if (weekIndexes.isEmpty) continue;
          
          weekIndexes.sort();
          
          int minWeek = weekIndexes.first;
          int maxWeek = weekIndexes.last;
          
          bool isConsecutive = true;
          bool isOdd = true;
          bool isEven = true;
          
          for (int i = 0; i < weekIndexes.length; i++) {
             if (weekIndexes[i] != minWeek + i) isConsecutive = false;
             if (weekIndexes[i] % 2 == 0) isOdd = false;
             if (weekIndexes[i] % 2 != 0) isEven = false;
          }
          
          int type = 0; // 0: All, 1: Odd, 2: Even
          if (isConsecutive) {
            type = 0;
            courses.add(_createCourse(tableId, courseName, weekday, room, teachers, startUnit, step, minWeek, maxWeek, type));
          } else if (isOdd) {
             bool isStrictStep2 = true;
             for(int i=0; i<weekIndexes.length-1; i++) {
                if (weekIndexes[i+1] - weekIndexes[i] != 2) isStrictStep2 = false;
             }
             if (isStrictStep2) {
               type = 1;
               courses.add(_createCourse(tableId, courseName, weekday, room, teachers, startUnit, step, minWeek, maxWeek, type));
             } else {
               _addComplexCourses(courses, tableId, courseName, weekday, room, teachers, startUnit, step, weekIndexes);
             }
          } else if (isEven) {
             bool isStrictStep2 = true;
             for(int i=0; i<weekIndexes.length-1; i++) {
                if (weekIndexes[i+1] - weekIndexes[i] != 2) isStrictStep2 = false;
             }
             if (isStrictStep2) {
               type = 2;
               courses.add(_createCourse(tableId, courseName, weekday, room, teachers, startUnit, step, minWeek, maxWeek, type));
             } else {
               _addComplexCourses(courses, tableId, courseName, weekday, room, teachers, startUnit, step, weekIndexes);
             }
          } else {
             // Mixed.
             _addComplexCourses(courses, tableId, courseName, weekday, room, teachers, startUnit, step, weekIndexes);
          }

        } catch (e) {
          debugPrint("Error parsing individual activity: $e");
        }
      }
    }
    
    return courses;
  }
  
  static void _addComplexCourses(List<Course> courses, int tableId, String name, int day, String room, String teacher, int startNode, int step, List<int> weeks) {
    if (weeks.isEmpty) return;
    
    int start = weeks[0];
    int prev = weeks[0];
    
    for (int i = 1; i < weeks.length; i++) {
      int current = weeks[i];
      if (current == prev + 1) {
        prev = current;
      } else {
        courses.add(_createCourse(tableId, name, day, room, teacher, startNode, step, start, prev, 0));
        start = current;
        prev = current;
      }
    }
    courses.add(_createCourse(tableId, name, day, room, teacher, startNode, step, start, prev, 0));
  }

  static Course _createCourse(int tableId, String name, int day, String room, String teacher, int startNode, int step, int startWeek, int endWeek, int type) {
    return Course(
      courseName: name,
      day: day,
      room: room,
      teacher: teacher,
      startNode: startNode,
      step: step,
      startWeek: startWeek,
      endWeek: endWeek,
      type: type,
      color: _generateColor(name),
      tableId: tableId,
    );
  }

  static String _generateColor(String name) {
    final colors = [
      "#FFCC80",
      "#FFAB91",
      "#E6EE9C",
      "#80CBC4",
      "#81D4FA",
      "#9FA8DA",
      "#CE93D8",
      "#EF9A9A",
    ];
    int hash = name.codeUnits.fold(0, (previous, element) => previous + element);
    return colors[hash % colors.length];
  }
}
