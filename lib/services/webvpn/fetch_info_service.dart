import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FetchInfoService {
  static const String _vpnSuffix = "vpn-12-o2-jxfw.sues.edu.cn";

  /// 1. 获取包含个人信息的JSON数据
  /// 
  /// 策略：
  /// - 先尝试自动寻找一个当前可用的 Semester ID
  /// - 使用该 ID 请求 print-data 接口 (与课表抓取同一个接口)
  /// - 如果接口返回数据，从中解析 studentTableVms -> 第一个对象 -> 基础信息
  static Future<Map<String, String>?> fetchStudentInfo(WebViewController controller, String baseUrl) async {
    try {
      // 步骤 1: 获取 Semester IDs
      final ids = await _fetchSemesterIds(controller);
      if (ids.isEmpty) {
        debugPrint("FetchInfoService: No semester IDs found.");
        return null;
      }
      
      // 步骤 2: 选择一个 ID (通常选最新的/最大的 ID 成功率较高)
      // Semester IDs are usually strings like "602", "581". Sort descending.
      ids.sort((a, b) {
        int? iA = int.tryParse(a);
        int? iB = int.tryParse(b);
        if (iA != null && iB != null) return iB.compareTo(iA);
        return b.compareTo(a);
      });
      
      String targetId = ids.first;
      debugPrint("FetchInfoService: Trying semester ID: $targetId");

      // 步骤 3: 请求数据
      // URL pattern: .../print-data?semesterId=...
      final url = "$baseUrl/student/for-std/course-table/semester/$targetId/print-data?$_vpnSuffix&semesterId=$targetId&hasExperiment=true";
      
      final jsonStr = await _fetchWithXhr(controller, url);
      if (jsonStr == null || !jsonStr.trim().startsWith('{')) {
          debugPrint("FetchInfoService: Invalid JSON response.");
          return null;
      }

      final data = jsonDecode(jsonStr);
      
      // 步骤 4: 解析个人信息
      if (data['studentTableVms'] != null && (data['studentTableVms'] as List).isNotEmpty) {
        final vm = data['studentTableVms'][0];
        
        final info = <String, String>{};
        if (vm['name'] != null) info['name'] = vm['name'].toString();
        if (vm['code'] != null) info['code'] = vm['code'].toString(); // 学号
        if (vm['grade'] != null) info['grade'] = vm['grade'].toString(); // 年级
        if (vm['department'] != null) info['department'] = vm['department'].toString(); // 学院
        if (vm['major'] != null) info['major'] = vm['major'].toString(); // 专业
        if (vm['adminclass'] != null) info['adminclass'] = vm['adminclass'].toString(); // 行政班
        
        return info;
      }
      
    } catch (e) {
      debugPrint("FetchInfoService Error: $e");
    }
    return null;
  }
  
  static Future<void> saveStudentInfo(Map<String, String> info) async {
    final prefs = await SharedPreferences.getInstance();
    if (info['name'] != null) await prefs.setString('user_nickname', info['name']!);
    if (info['code'] != null) await prefs.setString('student_id', info['code']!);
    if (info['major'] != null) await prefs.setString('user_major', info['major']!);
    if (info['department'] != null) await prefs.setString('user_college', info['department']!);
    if (info['adminclass'] != null) await prefs.setString('user_class', info['adminclass']!);
  }

  // --- Helpers (copied/shared from FetchCourseService) ---

  static Future<List<String>> _fetchSemesterIds(WebViewController controller) async {
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
      return [];
    }
  }

  static Future<String?> _fetchWithXhr(WebViewController controller, String url) async {
    try {
      final safeUrl = url.replaceAll("'", "\\'");
      final js = """
        (function() {
          try {
            var xhr = new XMLHttpRequest();
            xhr.open('GET', '$safeUrl', false);
            xhr.withCredentials = true; 
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
        return null;
      }
      return response;
    } catch (e) {
      return null;
    }
  }
}
