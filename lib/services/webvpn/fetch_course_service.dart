import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/course.dart';

class FetchCourseService {
  static const String _vpnSuffix = "vpn-12-o2-jxfw.sues.edu.cn";

  
  static Future<String?> _fetchWithXhr(WebViewController controller, String url) async {
    try {
      final safeUrl = url.replaceAll("'", "\\'");
      final key = '_fr_${DateTime.now().millisecondsSinceEpoch}';

      await controller.runJavaScript("""
        window['$key'] = null;
        window['${key}_done'] = false;
        (function() {
          try {
            var xhr = new XMLHttpRequest();
            xhr.open('GET', '$safeUrl', true);
            xhr.withCredentials = true;
            xhr.setRequestHeader('Accept', 'application/json, text/plain, */*');
            xhr.onload = function() {
              if (xhr.status >= 200 && xhr.status < 300) {
                window['$key'] = xhr.responseText;
              } else {
                window['$key'] = 'JS_ERROR: HTTP ' + xhr.status + ' ' + xhr.statusText;
              }
              window['${key}_done'] = true;
            };
            xhr.onerror = function() {
              window['$key'] = 'JS_ERROR: Network error';
              window['${key}_done'] = true;
            };
            xhr.send();
          } catch(e) {
            window['$key'] = 'JS_ERROR: ' + e.toString();
            window['${key}_done'] = true;
          }
        })();
      """);

      for (int i = 0; i < 100; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        final done = await controller.runJavaScriptReturningResult("window['${key}_done']");
        if (done.toString() == 'true') {
          final result = await controller.runJavaScriptReturningResult("window['$key']");
          await controller.runJavaScript("delete window['$key']; delete window['${key}_done'];");

          String response = "";
          if (result is String) {
            if (result.startsWith('"') && result.endsWith('"')) {
              try {
                response = jsonDecode(result);
              } catch (_) {
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
        }
      }

      debugPrint("WebView XHR Timeout for $url");
      return null;
    } catch (e) {
      debugPrint("WebView Eval Failed: $e");
      return null;
    }
  }

  
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

  
  static Future<Map<String, dynamic>?> fetchSemesterInfo(
      WebViewController controller, String baseUrl, String semesterId) async {
    
    
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

  
  static Future<Map<String, dynamic>?> fetchCourseData(
      WebViewController controller, String baseUrl, String semesterId) async {
    
    
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

  
  static List<Course> parseCourseData(Map<String, dynamic> json, int tableId) {
    if (!json.containsKey('studentTableVms')) return [];
    
    List<Course> courses = [];
    final vms = json['studentTableVms'] as List;
    if (vms.isEmpty) return [];

    
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
          
          int type = 0; 
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
      "#2196F3", 
      "#F44336", 
      "#4CAF50", 
      "#FF9800", 
      "#9C27B0", 
      "#009688", 
      "#E91E63", 
      "#3F51B5", 
      "#00BCD4", 
      "#795548"  
    ];
    int hash = name.codeUnits.fold(0, (previous, element) => previous + element);
    return colors[hash % colors.length];
  }
}
