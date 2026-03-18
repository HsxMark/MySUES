import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:html/parser.dart' show parse;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/exam.dart';
import 'fetch_info_service.dart';

class FetchExamService {
  

  static Future<List<Exam>> fetchExams(
    WebViewController controller, 
    String baseUrl, 
    {String? studentId}
  ) async {
    try {
      
      if (studentId == null || studentId.isEmpty) {
        
        final prefs = await SharedPreferences.getInstance();
        studentId = prefs.getString('user_internal_id');

        
        if (studentId == null) {
          final info = await FetchInfoService.fetchStudentInfo(controller, baseUrl);
          studentId = info?['id']; 
          
          if (studentId != null) {
            await FetchInfoService.saveStudentInfo(info!);
          }
        }

        if (studentId == null) {
          debugPrint("FetchExamService: Failed to retrieve student internal ID.");
          return [];
        }
      }

      
      
      final url = "$baseUrl/student/for-std/exam-arrange/info/$studentId";
      debugPrint("FetchExamService: Fetching exams from $url");

      
      final htmlString = await _fetchWithXhr(controller, url);
      if (htmlString == null || htmlString.isEmpty) {
        debugPrint("FetchExamService: Empty response.");
        return [];
      }

      
      return _parseExamHtml(htmlString);

    } catch (e) {
      debugPrint("FetchExamService Error: $e");
      return [];
    }
  }

  
  static List<Exam> _parseExamHtml(String htmlString) {
    final List<Exam> exams = [];
    final document = parse(htmlString);
    final tables = document.querySelectorAll('table');

    for (var table in tables) {
      
      var headers = <String>[];
      var headerRow = table.querySelector('thead tr');
      
      
      if (headerRow == null) {
        final firstRow = table.querySelector('tr');
        if (firstRow != null && firstRow.querySelectorAll('th').isNotEmpty) {
          headerRow = firstRow;
        }
      }
      
      if (headerRow != null) {
        headers = headerRow.querySelectorAll('th').map((e) => e.text.trim()).toList();
      }

      
      int nameIdx = _findHeaderIndex(headers, ['课程', '科目', 'Exam Course']);
      int timeIdx = _findHeaderIndex(headers, ['时间', 'Time', 'Exam Time']);
      int locIdx = _findHeaderIndex(headers, ['地点', '教室', 'Location', 'Room']);
      int typeIdx = _findHeaderIndex(headers, ['性质', 'Type']); 
      int statusIdx = _findHeaderIndex(headers, ['状态', 'Status']);

      
      
      bool useFallback = (nameIdx == -1 || timeIdx == -1);

      
      
      final rows = table.querySelectorAll('tr');
      
      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        
        
        if (cells.isEmpty) continue;
        
        
        
        if (cells.length == 1) continue;

        String courseName = "";
        String timeString = "";
        String location = "";
        String type = "";
        String status = "";

        if (!useFallback) {
          
          String getText(int idx) => idx >= 0 && idx < cells.length ? cells[idx].text.trim() : "";
          
          courseName = getText(nameIdx);
          timeString = getText(timeIdx);
          location = getText(locIdx);
          type = getText(typeIdx);
          status = getText(statusIdx);
        } else {
          
          
          
          
          
          
          if (cells.length >= 2) {
             final col0Text = cells[0].text.trim(); 
             final col1Text = cells[1].text.trim();
             final col2Text = cells.length > 2 ? cells[2].text.trim() : "";
             
             
             
             final timeRegExp = RegExp(r"(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}(?:[~-]\d{2}:\d{2})?)");
             final timeMatch = timeRegExp.firstMatch(col0Text);
             
             if (timeMatch != null) {
               timeString = timeMatch.group(0)!;
               
               location = col0Text.replaceAll(timeString, "").trim();
               
               location = location.replaceAll(RegExp(r'\s+'), ' ');
             } else {
               
               location = col0Text; 
             }
             
             
             
             final lines = col1Text.split(RegExp(r'\n+'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
                
             if (lines.isNotEmpty) {
               courseName = lines.first; 
               if (lines.length > 1) {
                 
                 
                 final lastLine = lines.last;
                 if (lastLine.length < 5 && (lastLine.contains("考") || lastLine.contains("期"))) {
                    type = lastLine;
                 }
               }
             } else {
               courseName = col1Text;
             }
             
             
             status = col2Text;
          }
        }
        
        
        
        if (courseName.isNotEmpty) {
          exams.add(Exam(
            courseName: courseName,
            timeString: timeString,
            location: location,
            type: type,
            status: status,
          ));
        }
      }
    }

    return exams;
  }

  static int _findHeaderIndex(List<String> headers, List<String> keywords) {
    for (int i = 0; i < headers.length; i++) {
      for (var keyword in keywords) {
        if (headers[i].contains(keyword)) {
          return i;
        }
      }
    }
    return -1;
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
            xhr.setRequestHeader('Accept', 'text/html, application/json, */*');
            xhr.onload = function() {
              if (xhr.status >= 200 && xhr.status < 300) {
                try {
                  var doc = new DOMParser().parseFromString(xhr.responseText, 'text/html');
                  var tables = doc.querySelectorAll('table');
                  var html = '';
                  for (var i = 0; i < tables.length; i++) {
                    html += tables[i].outerHTML;
                  }
                  window['$key'] = html || xhr.responseText;
                } catch(pe) {
                  window['$key'] = xhr.responseText;
                }
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
}
