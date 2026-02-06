import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import '../services/networking/academic_client.dart'; // Added
import '../services/parsers/course_parser.dart';
import '../services/parsers/score_parser.dart';
import '../services/parsers/exam_parser.dart';
import '../services/parsers/student_info_parser.dart';
import '../models/schedule_table.dart';
import '../models/course.dart';
import '../services/schedule_service.dart';
import '../services/score_service.dart';
import '../services/exam_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginWebviewScreen extends StatefulWidget {
  const LoginWebviewScreen({super.key});

  @override
  State<LoginWebviewScreen> createState() => _LoginWebviewScreenState();
}

class _LoginWebviewScreenState extends State<LoginWebviewScreen> {
  late final WebViewController _controller;
  final AcademicClient _academicClient = AcademicClient();
  
  bool _isLoading = true;
  String _currentStep = '请登录 教务系统';
  
  // URLs
  static const String initialUrl = 'https://webvpn.sues.edu.cn/login';

  // Known Academic System Hex ID for SUES WebVPN
  // Decoded from: https://webvpn.sues.edu.cn/...203b -> jxfw.sues.edu.cn
  static const String _academicHex = '77726476706e69737468656265737421faef478b69237d556d468ca88d1b203b';

  // Dynamic base URL detected from user navigation
  String? _detectedVpnBase;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      // ..setUserAgent("...") // Use system default UserAgent to avoid compatibility issues
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Allow all navigations
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
              _detectBaseUrl(url);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              _detectBaseUrl(url);
              _checkPageContent();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("Web error: ${error.description}, Code: ${error.errorCode}");
            // Handle ERR_CACHE_MISS (Avoid infinite reload loop)
            if (error.description.contains("CACHE_MISS")) {
               debugPrint("Encountered ERR_CACHE_MISS. Suggest user to go back or refresh manually.");
               // Do NOT auto reload here as it causes infinite loops if the POST data is gone.
            }
            if (mounted) {
               setState(() => _isLoading = false);
            }
          },
        ),
      );
    
    // Clear cache to resolve persistent ERR_CACHE_MISS
    await _controller.clearCache();
    await _controller.clearLocalStorage();
    
    if (mounted) {
      _controller.loadRequest(Uri.parse(initialUrl));
    }
  }

  // Auto-detect the correct proxy info from URL
  void _detectBaseUrl(String url) {
    debugPrint("Checking URL: $url");
    final uri = Uri.parse(url);
    if (uri.host == 'webvpn.sues.edu.cn') {
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'https') {
        final hexKey = segments[1];
        // Supports both keys e.g. /https/HEX/eams or /https/HEX/student
        final newBase = "https://webvpn.sues.edu.cn/https/$hexKey";
        if (_detectedVpnBase != newBase) {
           _detectedVpnBase = newBase;
           debugPrint("Detected VPN Base: $_detectedVpnBase");
        }
      }
    }
  }
  
  Future<void> _checkPageContent() async {
    final String? url = await _controller.currentUrl();
    if (url != null && url.contains("/student/home")) {
        setState(() => _currentStep = "登录成功，请点击下方按钮提取数据");
    } else {
        final String? title = await _controller.getTitle();
        if (title != null) {
          if (title.contains("登录") || title.contains("Login")) {
            setState(() => _currentStep = "请登录您的账号");
          } 
        }
    }
  }

  Future<String> _getCookieString() async {
    // Only use document.cookie which is available via JS
    // Note: This misses HttpOnly cookies, so for API calls that require session,
    // we should use _fetchWithXhr to execute requests inside the WebView context.
    try {
      final String result = await _controller.runJavaScriptReturningResult('document.cookie') as String;
      return _decodeJsString(result);
    } catch (e) {
      return "";
    }
  }

  // Execute a synchronous XHR request inside the WebView to leverage its full cookie/session context
  Future<String?> _fetchWithXhr(String url) async {
    try {
      // Escape the URL for JS string
      final safeUrl = url.replaceAll("'", "\\'");
      final js = """
        (function() {
          try {
            var xhr = new XMLHttpRequest();
            xhr.open('GET', '$safeUrl', false); // Synchronous
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
      
      final result = await _controller.runJavaScriptReturningResult(js);
      String response = "";
      if (result is String) {
         response = _decodeJsString(result);
      } else {
         response = result.toString(); // Should be a string representation or fallback
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


  Future<void> _extractCourse() async {
    try {
      // Use detected URL or fallback to known hex
      String targetBase = _detectedVpnBase ?? "https://webvpn.sues.edu.cn/https/$_academicHex";
      
      _showSnack("正在尝试提取数据的 Semester ID...");
      final cookie = await _getCookieString();
      
      // Get UserAgent from WebView to avoid "Environment Security Check" failure
      String userAgent = "";
      try {
        final uaResult = await _controller.runJavaScriptReturningResult("navigator.userAgent");
        userAgent = _decodeJsString(uaResult.toString());
        debugPrint("WebView UA: $userAgent");
      } catch (e) {
        debugPrint("Failed to get UA: $e");
      }
      
      String? html;
      String? semesterId;
      
      // Attempt 1: New System (Student)
      try {
        // Try getting HTML/Data from WebView directly first (most reliable for SPAs/VPNs)
        try {
           final webHtml = await _controller.runJavaScriptReturningResult("document.documentElement.outerHTML");
           html = _decodeJsString(webHtml as String);
        } catch (e) {
           debugPrint("WebView HTML fetch failed: $e");
        }
        
        // Logic to find semester ID from HTML or JS context
        if (html != null) {
           // Regex 1: Standard var semesters = JSON.parse(...)
           var semMatch = RegExp(r"var semesters = JSON\.parse\('([^']*)'\)").firstMatch(html!);
           if (semMatch != null) {
              String semJsonStr = semMatch.group(1) ?? "";
              semJsonStr = semJsonStr.replaceAll(r'\"', '"'); 
              try {
                List<dynamic> sems = jsonDecode(semJsonStr);
                if (sems.isNotEmpty) {
                   // Find the one marked as current if possible, or just max id
                   // Sues usually has `id`
                   sems.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
                   semesterId = sems.first['id'].toString();
                }
              } catch (e) { print("Parse semesters error: $e"); }
           }
           
           // Regex 2: Look for 'semesterId' in the rendered HTML
           if (semesterId == null) {
               final semIdMatch = RegExp(r'"semester"\s*:\s*\{\s*"id"\s*:\s*(\d+)').firstMatch(html!);
               if (semIdMatch != null) semesterId = semIdMatch.group(1);
           }
        }

        if (semesterId != null) {
             debugPrint("Detected Semester ID: $semesterId");
        }
      } catch (e) {
        debugPrint("New system check failed: $e");
      }

      final int tableId = DateTime.now().millisecondsSinceEpoch;
      
      final parser = CourseParser();
      List<dynamic> courses = [];
      String debugResponse = "";

      // Headers construction for consistent identity
      Map<String, String> extraHeaders = {
        'Referer': "$targetBase/student/for-std/course-table",
        'Accept': 'application/json, text/plain, */*',
        if (userAgent.isNotEmpty) 'User-Agent': userAgent,
      };

      // If found semesterId, fetch JSON data
      if (semesterId != null) {
         try {
           _showSnack("检测到 ID: $semesterId，正在请求数据...");
           final jsonUrl = "$targetBase/student/for-std/course-table/semester/$semesterId/print-data?semesterId=$semesterId&hasExperiment=true";
           
           // Use XHR from WebView to ensure HttpOnly cookies are sent
           final jsonStr = await _fetchWithXhr(jsonUrl);
           
           if (jsonStr != null) {
              if (jsonStr.trim().startsWith('{')) {
                  courses = parser.parse(jsonStr, tableId);
                  if (courses.isNotEmpty) _showSnack("检测到新系统数据 (${courses.length} 门课)");
              } else {
                  debugResponse = jsonStr.substring(0, jsonStr.length > 200 ? 200 : jsonStr.length);
                  debugPrint("Expect JSON but got: $debugResponse");
              }
           }
         } catch(e) {
           debugPrint("JSON Fetch failed: $e");
           _showSnack("请求遇到错误: $e");
         }
      }

      // Fallback: Parse HTML (Old EAMS or whatever html we have)
      if (courses.isEmpty) {
         // Only try fetching old EAMS if we haven't already extracted something
         if (html == null || !html!.contains("table")) {
             debugPrint("Trying fallback EAMS HTML fetch...");
             // EAMS usually works with standard cookies (non-HttpOnly might suffer)
             // But let's try XHR for it too if possible, or fallback to Client
             // XHR might fail for cross-origin redirects if any.
             // Sticking to Client for EAMS as it might be safer for heavy HTML? 
             // Actually XHR is better for session.
             final eamsUrl = "$targetBase/eams/courseTableForStd.action";
             final eamsHtml = await _fetchWithXhr(eamsUrl);
             
             if (eamsHtml != null) {
               html = eamsHtml;
             } else {
                // Last resort Client
                html = await _academicClient.fetchHtmlWithCookie(
                  eamsUrl, 
                  cookie,
                  headers: {
                    'Referer': "$targetBase/eams/home.action",
                    if (userAgent.isNotEmpty) 'User-Agent': userAgent,
                  }
                );
             }
         }
         if (html != null && html!.isNotEmpty) {
             // Try parsing as HTML
             var legacyCourses = parser.parse(html!, tableId);
             if (legacyCourses.isNotEmpty) {
                courses = legacyCourses;
             }
         }
      }
      
      // Manual ID Fallback
      if (courses.isEmpty) {
        if (!mounted) return;
        
        String dialogContent = "未能自动检测到数据。";
        if (debugResponse.isNotEmpty) {
           dialogContent += "\n\n上次请求返回非JSON数据:\n$debugResponse\n\n可能是登录已过期或接口被拦截。";
        }
        dialogContent += "\n\n如果您知道 Semester ID (如 602)，请尝试手动输入：";

        final TextEditingController idController = TextEditingController();
        final String? manualId = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("手动尝试"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dialogContent, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: idController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Semester ID",
                      hintText: "查看抓包 print-data 中的 ID",
                      border: OutlineInputBorder()
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
              TextButton(onPressed: () => Navigator.pop(context, idController.text), child: const Text("确定")),
            ],
          ),
        );

        if (manualId != null && manualId.isNotEmpty) {
           try {
             _showSnack("正在请求 ID: $manualId ...");
             final jsonUrl = "$targetBase/student/for-std/course-table/semester/$manualId/print-data?semesterId=$manualId&hasExperiment=true";
             
             // XHR again
             final jsonStr = await _fetchWithXhr(jsonUrl);

             if (jsonStr != null && jsonStr.trim().startsWith('{')) {
                courses = parser.parse(jsonStr, tableId);
                // Important: Update semesterId so subsequent info fetching works
                semesterId = manualId;
             } else {
                 String failReason = jsonStr != null 
                    ? jsonStr.substring(0, jsonStr.length > 100 ? 100 : jsonStr.length) 
                    : "空响应";
                 _showSnack("请求失败: 返回内容不是 JSON ($failReason)");
             }
           } catch (e) {
             debugPrint("Manual ID fetch failed: $e");
             _showSnack("请求异常: $e");
           }
        }
      }

      if (courses.isEmpty) {
        _showSnack("最终提取失败，请确保已登录并在课表页面");
        return;
      }

      if (courses.isEmpty) {
        _showSnack("未检测到有效课表数据，请确认已登录并处于课表页面");
        return;
      }

      // Try automatic info fetching (Semester Name & Start Date)
      String tableName = "Web导入课表";
      String? startDateStr;

      if (semesterId != null) {
          try {
             _showSnack("正在获取学期详情...");
             // e.g. /student/ws/semester/get/602
             final semInfoUrl = "$targetBase/student/ws/semester/get/$semesterId";
             debugPrint("Fetching info from: $semInfoUrl");
             
             final semInfoStr = await _fetchWithXhr(semInfoUrl);
             debugPrint("Semester Info Response: $semInfoStr");

             if (semInfoStr != null && semInfoStr.trim().startsWith('{')) {
                 final semInfo = jsonDecode(semInfoStr);
                 if (semInfo['nameZh'] != null) {
                    tableName = semInfo['nameZh'];
                 }
                 if (semInfo['startDate'] != null) {
                    startDateStr = semInfo['startDate'];
                 }
             } else {
                 _showSnack("获取学期详情失败: 响应为空或格式错误");
             }
          } catch (e) {
             debugPrint("Semester info fetch failed: $e");
             _showSnack("获取学期详情异常: $e");
          }
      }

      // Selecting Start Date (If not auto-detected)
      if (startDateStr == null) {
        if (!mounted) return;
        
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          helpText: "请选择本学期第一周的周一",
        );

        if (pickedDate == null) {
           _showSnack("已取消导入");
           return;
        }
        startDateStr = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      } else {
         _showSnack("自动获取开学日期: $startDateStr");
      }

      final newTable = ScheduleTable(
          id: tableId,
          tableName: tableName,
          startDate: startDateStr!, 
          maxWeek: 20
      );

      await ScheduleDataService.addScheduleTable(newTable);
      
      // Update courses with the actual ID assigned by the service (it uses auto-increment)
      // Note: newTable.id is updated in place by addScheduleTable
      final int realTableId = newTable.id;
      debugPrint("Saving courses to Table ID: $realTableId (Original: $tableId)");
      
      for (var c in courses) {
        // Update tableId matches the saved table
        if (c is Course) {
            c.tableId = realTableId;
            await ScheduleDataService.addCourse(c);
        } else if (c is Map) {
            // Should be Course objects, but just in case of dynamic
             await ScheduleDataService.addCourse(c as dynamic); 
        }
      }
      
      // Auto-switch to the new table
      await ScheduleDataService.setCurrentTableId(realTableId);
      
      _showSnack("成功导入 ${courses.length} 门课程！");
      _recordSyncTime();
    } catch (e) {
      _showSnack("提取失败: $e");
    }
  }

  Future<void> _extractScore() async {
    try {
      String targetBase = _detectedVpnBase ?? "https://webvpn.sues.edu.cn/https/$_academicHex";
      _showSnack("正在通过WebVPN接口提取成绩...");
      final cookie = await _getCookieString();
      
      final html = await _academicClient.postHtmlWithCookie(
        "$targetBase/eams/teach/grade/course/person!historyCourseGrade.action", 
        cookie,
        data: {'projectType': 'MAJOR'}
      );
      
      if (html == null || html.isEmpty) {
        throw "无法获取数据";
      }
      
      final parser = ScoreParser();
      final scores = parser.parse(html);
      
      if (scores.isEmpty) {
        _showSnack("未检测到成绩数据");
        return;
      }
      
      await ScoreService.saveScores(scores);
      _showSnack("成功导入 ${scores.length} 条成绩记录！");
      _recordSyncTime();
    } catch (e) {
      _showSnack("提取失败: $e");
    }
  }

  Future<void> _extractExam() async {
    try {
      String targetBase = _detectedVpnBase ?? "https://webvpn.sues.edu.cn/https/$_academicHex";
      _showSnack("正在通过WebVPN接口提取考试...");
      final cookie = await _getCookieString();
      
      final html = await _academicClient.postHtmlWithCookie(
        "$targetBase/eams/stdExamTable!examTable.action", 
        cookie,
        data: {
          'sort': 'examTime',
          'order': 'desc',
          'projectType': 'MAJOR'
        }
      );
      
      if (html == null || html.isEmpty) {
        throw "无法获取数据";
      }
      
      final parser = ExamParser();
      final exams = parser.parse(html);
      
      if (exams.isEmpty) {
        _showSnack("未检测到考试数据");
        return;
      }
      
      await ExamService.saveExams(exams);
      _showSnack("成功导入 ${exams.length} 条考试记录！");
      _recordSyncTime();
    } catch (e) {
      _showSnack("提取失败: $e");
    }
  }

  Future<void> _extractInfo() async {
    // Info is usually on the home page or specific page. 
    // CourseAdapter might not have a dedicated info parser or uses one of the pages.
    // We'll try fetching the home page or student info page.
    try {
       String targetBase = _detectedVpnBase ?? "https://webvpn.sues.edu.cn/https/$_academicHex";
       
       // Try fetching the user detail page or just header info from course page
       // Let's reuse course page as it usually contains student info in header
       final cookie = await _getCookieString();
       final html = await _academicClient.fetchHtmlWithCookie(
        "$targetBase/eams/courseTableForStd.action", 
        cookie
      );
      
      if (html == null) throw "Network Error";

      final parser = StudentInfoParser();
      final info = parser.parse(html);
      
      if (info.isEmpty || info['name'] == null) {
        _showSnack("未检测到个人信息");
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      if (info['name'] != null) await prefs.setString('user_nickname', info['name']!);
      if (info['studentId'] != null) await prefs.setString('student_id', info['studentId']!);
      if (info['major'] != null) await prefs.setString('user_major', info['major']!);
      if (info['college'] != null) await prefs.setString('user_college', info['college']!);
      
      String msg = "已更新信息: ${info['name']}";
      if (info['studentId'] != null) msg += " (${info['studentId']})";
      _showSnack(msg);
      _recordSyncTime();
    } catch (e) {
      _showSnack("提取失败: $e");
    }
  }

  String _decodeJsString(String jsInfo) {
    try {
      // webview_flutter returns a JSON string representation
      return jsonDecode(jsInfo).toString();
    } catch (e) {
      debugPrint("JSON Decode error: $e");
      // Fallback manual decode if jsonDecode fails
      if (jsInfo.startsWith('"') && jsInfo.endsWith('"')) {
         return jsInfo.substring(1, jsInfo.length - 1)
              .replaceAll(r'\"', '"')
              .replaceAll(r'\\', r'\');
      }
      return jsInfo;
    }
  }

  Future<void> _recordSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_time_academic', DateTime.now().toString().substring(0, 16));
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WebVPN 网页提取"),
        actions: [
            IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: "清理缓存",
                onPressed: () async {
                  await _controller.clearCache();
                  await _controller.clearLocalStorage();
                  if (mounted) _showSnack("缓存已清理");
                  _controller.reload();
                },
            ),
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _controller.reload(),
            ),
             IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => _controller.loadRequest(Uri.parse(initialUrl)),
            )
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(30),
            child: Container(
                color: Colors.blue.shade50,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                    _currentStep, 
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                    textAlign: TextAlign.center,
                ),
            ),
        ),
      ),
      body: Stack(
        children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) 
                const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          "请选择要提取的内容",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text("提取个人信息"),
                          onTap: () {
                            Navigator.pop(context);
                            _extractInfo();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.calendar_month),
                          title: const Text("提取课表"),
                          subtitle: const Text("需选择开学日期"),
                          onTap: () {
                            Navigator.pop(context);
                            _extractCourse();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.score),
                          title: const Text("提取成绩"),
                          onTap: () {
                            Navigator.pop(context);
                            _extractScore();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.assignment),
                          title: const Text("提取考试安排"),
                          onTap: () {
                            Navigator.pop(context);
                            _extractExam();
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.menu_open),
              label: const Text("提取菜单", style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}
