import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/score.dart';

class FetchScoreService {
  static const String _vpnSuffix = "vpn-12-o2-jxfw.sues.edu.cn";

  /// 异步 XHR 获取页面内容（兼容 iOS WKWebView）
  static Future<String?> _fetchWithXhr(
    WebViewController controller,
    String url, {
    bool Function()? isCancelled,
  }) async {
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
        if (isCancelled?.call() ?? false) {
          debugPrint("WebView XHR aborted by caller: $url");
          return null;
        }
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

  /// 获取单个学期的成绩
  static Future<List<Score>> fetchSemesterScores(
    WebViewController controller,
    String baseUrl,
    String studentId,
    String semesterId, {
    bool Function()? isCancelled,
  }) async {
    if (isCancelled?.call() ?? false) return [];
    // API format: /student/for-std/grade/sheet/info/{studentId}?{VPN_SUFFIX}&semester={semesterId}
    final url = "$baseUrl/student/for-std/grade/sheet/info/$studentId?$_vpnSuffix&semester=$semesterId";

    final jsonStr = await _fetchWithXhr(
      controller,
      url,
      isCancelled: isCancelled,
    );
    if (isCancelled?.call() ?? false) return [];
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
  ///
  /// Returns an empty list as soon as [isCancelled] reports true, so a
  /// cancelled run never hands partial score data to the caller.
  static Future<List<Score>> fetchAllScores(
    WebViewController controller,
    String baseUrl,
    String studentId,
    List<String> semesterIds, {
    bool Function()? isCancelled,
  }) async {
    List<Score> allScores = [];

    // 倒序遍历，或者全部获取
    for (var semId in semesterIds) {
      if (isCancelled?.call() ?? false) return const [];
      debugPrint("Fetching scores for semester $semId...");
      final scores = await fetchSemesterScores(
        controller,
        baseUrl,
        studentId,
        semId,
        isCancelled: isCancelled,
      );
      if (isCancelled?.call() ?? false) return const [];
      allScores.addAll(scores);
      // Optional: Add delay if needed to avoid spamming
      await Future.delayed(const Duration(milliseconds: 200));
    }

    return allScores;
  }
}
