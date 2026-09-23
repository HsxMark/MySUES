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
    {String? studentId, bool Function()? isCancelled}
  ) async {
    try {
      if (isCancelled?.call() ?? false) return const [];
      // 1. 如果没有提供 studentId，先获取
      if (studentId == null || studentId.isEmpty) {
        // 先尝试从本地读取 internal ID
        final prefs = await SharedPreferences.getInstance();
        studentId = prefs.getString('user_internal_id');

        // 如果本地没有，则联网获取
        if (studentId == null) {
          final info = await FetchInfoService.fetchStudentInfo(
            controller,
            baseUrl,
            isCancelled: isCancelled,
          );
          if (isCancelled?.call() ?? false) return const [];
          studentId = info?['id']; // 使用内部 ID (如 12345)，而不是学号
          
          if (studentId != null) {
            await FetchInfoService.saveStudentInfo(info!);
          }
        }

        if (studentId == null) {
          debugPrint("FetchExamService: Failed to retrieve student internal ID.");
          return [];
        }
      }

      // 2. 构造请求 URL
      // Python: BASE_URL/student/for-std/exam-arrange/info/{student_id}
      final url = "$baseUrl/student/for-std/exam-arrange/info/$studentId";
      debugPrint("FetchExamService: Fetching exams from $url");

      // 3. 获取 HTML 内容
      final htmlString = await _fetchWithXhr(
        controller,
        url,
        isCancelled: isCancelled,
      );
      if (isCancelled?.call() ?? false) return const [];
      if (htmlString == null || htmlString.isEmpty) {
        debugPrint("FetchExamService: Empty response.");
        return [];
      }

      // 4. 解析 HTML
      return _parseExamHtml(htmlString);

    } catch (e) {
      debugPrint("FetchExamService Error: $e");
      return [];
    }
  }

  /// 使用 html 库解析网页表格数据
  static List<Exam> _parseExamHtml(String htmlString) {
    final List<Exam> exams = [];
    final document = parse(htmlString);
    final tables = document.querySelectorAll('table');

    for (var table in tables) {
      // 1. 尝试寻找和解析表头（兼容 thead 或 第一行 tr）
      var headers = <String>[];
      var headerRow = table.querySelector('thead tr');
      
      // 如果没有 thead，尝试找第一个包含 th 的 tr
      if (headerRow == null) {
        final firstRow = table.querySelector('tr');
        if (firstRow != null && firstRow.querySelectorAll('th').isNotEmpty) {
          headerRow = firstRow;
        }
      }
      
      if (headerRow != null) {
        headers = headerRow.querySelectorAll('th').map((e) => e.text.trim()).toList();
      }

      // 2. 尝试定位列索引 (Standard Strategy)
      int nameIdx = _findHeaderIndex(headers, ['课程', '科目', 'Exam Course']);
      int timeIdx = _findHeaderIndex(headers, ['时间', 'Time', 'Exam Time']);
      int locIdx = _findHeaderIndex(headers, ['地点', '教室', 'Location', 'Room']);
      int typeIdx = _findHeaderIndex(headers, ['性质', 'Type']); 
      int statusIdx = _findHeaderIndex(headers, ['状态', 'Status']);

      // 3. 判断是否需要启用“备用解析逻辑” (Fallback Strategy)
      // 如果找不到关键列（时间、课程），或者表头根本不存在，则启用
      bool useFallback = (nameIdx == -1 || timeIdx == -1);

      // 4. 遍历所有行
      // 注意：querySelector('tr') 会获取所有行，包括 thead 里的。我们需要自行过滤。
      final rows = table.querySelectorAll('tr');
      
      for (var row in rows) {
        final cells = row.querySelectorAll('td');
        
        // 跳过：如果是表头行（全是 th）或空行
        if (cells.isEmpty) continue;
        
        // 跳过：特殊的提示行，如 "col_0": "暂无\"未结束\"的考试安排"
        // 这种行通常只有 1 列
        if (cells.length == 1) continue;

        String courseName = "";
        String timeString = "";
        String location = "";
        String type = "";
        String status = "";

        if (!useFallback) {
          // --- 策略 A: 标准表头解析 ---
          String getText(int idx) => idx >= 0 && idx < cells.length ? cells[idx].text.trim() : "";
          
          courseName = getText(nameIdx);
          timeString = getText(timeIdx);
          location = getText(locIdx);
          type = getText(typeIdx);
          status = getText(statusIdx);
        } else {
          // --- 策略 B: 混合内容解析 (基于用户提供的 JSON 样本) ---
          // 典型结构 (3列):
          // Col 0: 时间 + 地点 (例如: "2025-11-12 12:15~14:15\n 松江校区...")
          // Col 1: 课程 + 性质 (例如: "机器学习 \n 期末")
          // Col 2: 状态 (例如: "已结束")
          
          if (cells.length >= 2) {
             final col0Text = cells[0].text.trim(); 
             final col1Text = cells[1].text.trim();
             final col2Text = cells.length > 2 ? cells[2].text.trim() : "";
             
             // -> 解析 Col 0 (时间 + 地点)
             // 匹配日期时间: YYYY-MM-DD HH:MM[~HH:MM]
             final timeRegExp = RegExp(r"(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}(?:[~-]\d{2}:\d{2})?)");
             final timeMatch = timeRegExp.firstMatch(col0Text);
             
             if (timeMatch != null) {
               timeString = timeMatch.group(0)!;
               // 地点 = 原文本 - 时间, 再清理空白
               location = col0Text.replaceAll(timeString, "").trim();
               // 压缩多个空白字符为一个空格
               location = location.replaceAll(RegExp(r'\s+'), ' ');
             } else {
               // 如果匹配不到时间，回退：整个当做地点？这通常意味着解析失败或数据异常
               location = col0Text; 
             }
             
             // -> 解析 Col 1 (课程 + 性质)
             // 分割换行符，去除空行
             final lines = col1Text.split(RegExp(r'\n+'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
                
             if (lines.isNotEmpty) {
               courseName = lines.first; // 第一行通常是课名
               if (lines.length > 1) {
                 // 最后一行通常是性质 (补考/期末)
                 // 判断一下长度，避免把很长的课名切断了
                 final lastLine = lines.last;
                 if (lastLine.length < 5 && (lastLine.contains("考") || lastLine.contains("期"))) {
                    type = lastLine;
                 }
               }
             } else {
               courseName = col1Text;
             }
             
             // -> 解析 Col 2 (状态)
             status = col2Text;
          }
        }
        
        // 5. 过滤并添加有效数据
        // 至少要有课程名
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

  /// 通过异步 XHR 获取页面内容（兼容 iOS WKWebView，不使用同步 XHR）
  /// 注意：考试接口返回完整 HTML 页面，iOS WKWebView 的 JS 桥在传递大字符串时
  /// 可能截断或编码异常，因此在 JS 侧预提取 <table> 元素以减少传输数据量。
  static Future<String?> _fetchWithXhr(
    WebViewController controller,
    String url, {
    bool Function()? isCancelled,
  }) async {
    try {
      final safeUrl = url.replaceAll("'", "\\'");
      final key = '_fr_${DateTime.now().millisecondsSinceEpoch}';

      // 启动异步 XHR（iOS WKWebView 不支持同步 XHR）
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

      // 轮询等待结果（最多 10 秒）
      for (int i = 0; i < 100; i++) {
        if (isCancelled?.call() ?? false) {
          debugPrint("WebView XHR aborted by caller: $url");
          return null;
        }
        await Future.delayed(const Duration(milliseconds: 100));
        final done = await controller.runJavaScriptReturningResult("window['${key}_done']");
        if (done.toString() == 'true') {
          final result = await controller.runJavaScriptReturningResult("window['$key']");
          // 清理全局变量
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
