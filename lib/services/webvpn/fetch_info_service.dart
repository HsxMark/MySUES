import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' show parse;

class FetchInfoService {
  static const String _vpnSuffix = "vpn-12-o2-jxfw.sues.edu.cn";

  
  
  
  
  
  static Future<Map<String, String>?> fetchStudentInfo(WebViewController controller, String baseUrl) async {
    try {
      
      
      final ids = await _fetchSemesterIds(controller, baseUrl);
      if (ids.isEmpty) {
        debugPrint("FetchInfoService: No semester IDs found.");
        return null;
      }

      
      ids.sort((a, b) {
        int? iA = int.tryParse(a);
        int? iB = int.tryParse(b);
        if (iA != null && iB != null) return iB.compareTo(iA);
        return b.compareTo(a);
      });
      
      String targetId = ids.first;
      debugPrint("FetchInfoService: Trying semester ID: $targetId");

      
      final url = "$baseUrl/student/for-std/course-table/semester/$targetId/print-data?$_vpnSuffix&semesterId=$targetId&hasExperiment=true";
      
      final jsonStr = await _fetchWithXhr(controller, url);
      if (jsonStr == null || !jsonStr.trim().startsWith('{')) {
          debugPrint("FetchInfoService: Invalid JSON response.");
          return null;
      }

      final data = jsonDecode(jsonStr);
      
      
      if (data['studentTableVms'] != null && (data['studentTableVms'] as List).isNotEmpty) {
        final vm = data['studentTableVms'][0];
        
        final info = <String, String>{};
        if (vm['name'] != null) info['name'] = vm['name'].toString();
        if (vm['code'] != null) info['code'] = vm['code'].toString(); 
        if (vm['id'] != null) info['id'] = vm['id'].toString(); 
        if (vm['grade'] != null) info['grade'] = vm['grade'].toString(); 
        if (vm['department'] != null) info['department'] = vm['department'].toString(); 
        if (vm['major'] != null) info['major'] = vm['major'].toString(); 
        if (vm['adminclass'] != null) info['adminclass'] = vm['adminclass'].toString(); 
        
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
    if (info['id'] != null) await prefs.setString('user_internal_id', info['id']!);
    if (info['major'] != null) await prefs.setString('user_major', info['major']!);
    if (info['department'] != null) await prefs.setString('user_college', info['department']!);
    if (info['adminclass'] != null) await prefs.setString('user_class', info['adminclass']!);
  }

  

  static Future<List<String>> _fetchSemesterIds(WebViewController controller, String baseUrl) async {
    const relativeUrl = "/student/for-std/course-table";
    final url = "$baseUrl$relativeUrl";
    
    try {
      
      final html = await _fetchWithXhr(controller, url);
      if (html == null || html.isEmpty) return [];

      
      final document = parse(html);
      final select = document.getElementById('add-drop-take-semesters');
      if (select == null) return [];

      
      final ids = <String>[];
      for (var option in select.getElementsByTagName('option')) {
        final val = option.attributes['value'];
        if (val != null && val.isNotEmpty && val != 'all') {
          ids.add(val);
        }
      }
      return ids;
    } catch (e) {
      debugPrint("FetchInfoService: Error fetching semester IDs: $e");
      return [];
    }
  }

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
            return null;
          }
          return response;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
