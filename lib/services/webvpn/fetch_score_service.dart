import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/score.dart';

class FetchScoreService {
  static const String _vpnSuffix = "vpn-12-o2-jxfw.sues.edu.cn";

  /// 这里的 _fetchWithXhr 与 FetchCourseService 中的相同
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
        debugPrint("WebView XHR Failed for $url: $response");
        return null;
      }
      return response;
    } catch (e) {
      debugPrint("WebView Eval Failed: $e");
      return null;
    }
  }

  /// 获取单个学期的成绩
  static Future<List<Score>> fetchSemesterScores(
      WebViewController controller, String baseUrl, String studentId, String semesterId) async {
    // API format: /student/for-std/grade/sheet/info/{studentId}?{VPN_SUFFIX}&semester={semesterId}
    final url = "$baseUrl/student/for-std/grade/sheet/info/$studentId?$_vpnSuffix&semester=$semesterId";
    
    final jsonStr = await _fetchWithXhr(controller, url);
    if (jsonStr == null) return [];

    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      
      // Structure: data['semesterId2studentGrades'][semesterId] -> List<Object>
      // Also data['semesters'] or data['id2semesters'][semesterId]['nameZh'] for semester name
      
      if (data['semesterId2studentGrades'] == null) return [];

      final gradesMap = data['semesterId2studentGrades'] as Map<String, dynamic>;
      
      // 尝试直接获取
      var gradesList = gradesMap[semesterId];
      
      // 如果获取失败，尝试强转 string 遍历匹配
      if (gradesList == null) {
        for (var key in gradesMap.keys) {
          if (key.toString() == semesterId.toString()) {
            gradesList = gradesMap[key];
            break;
          }
        }
      }

      if (gradesList is List) {
        // Try to get semester name from this response
        String semesterName = "未知学期";
        if (data['id2semesters'] != null) {
           final idMap = data['id2semesters'] as Map<String, dynamic>;
           // 同理尝试匹配 semester
           var semInfo = idMap[semesterId];
           if (semInfo == null) {
             for (var key in idMap.keys) {
               if (key.toString() == semesterId.toString()) {
                 semInfo = idMap[key];
                 break;
               }
             }
           }
           
           if (semInfo != null && semInfo['nameZh'] != null) {
             semesterName = semInfo['nameZh'];
           }
        }

        debugPrint("Found ${gradesList.length} scores for semester $semesterId ($semesterName)");

        return gradesList.map<Score>((item) {
           return Score.fromApiJson(item as Map<String, dynamic>, semesterName);
        }).toList();
      }
    } catch (e) {
      debugPrint("Error parsing score json for sem $semesterId: $e");
    }

    return [];
  }

  /// 批量获取所有学期成绩
  static Future<List<Score>> fetchAllScores(
      WebViewController controller, String baseUrl, String studentId, List<String> semesterIds) async {
    List<Score> allScores = [];
    
    // 倒序遍历，或者全部获取
    for (var semId in semesterIds) {
      debugPrint("Fetching scores for semester $semId...");
      final scores = await fetchSemesterScores(controller, baseUrl, studentId, semId);
      allScores.addAll(scores);
      // Optional: Add delay if needed to avoid spamming
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    return allScores;
  }
}
