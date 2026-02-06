import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import '../services/networking/academic_client.dart'; // Added
import '../services/parsers/course_parser.dart';
import '../services/parsers/score_parser.dart';
import '../services/parsers/exam_parser.dart';
import '../services/parsers/student_info_parser.dart';
import '../models/schedule_table.dart';
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
  String _currentStep = '请登录 WebVPN / 教务系统';
  
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
    final String? title = await _controller.getTitle();
    if (title != null) {
      if (title.contains("登录") || title.contains("Login")) {
        setState(() => _currentStep = "请登录您的账号");
      } else if (title.contains("Sues") || title.contains("工程大")) {
        setState(() => _currentStep = "登录成功，点击下方按钮提取数据");
      }
    }
  }
  
  Future<String> _getCookieString() async {
    final String result = await _controller.runJavaScriptReturningResult('document.cookie') as String;
    return _decodeJsString(result);
  }

  Future<void> _extractCourse() async {
    try {
      // Use detected URL or fallback to known hex
      String targetBase = _detectedVpnBase ?? "https://webvpn.sues.edu.cn/https/$_academicHex";
      
      _showSnack("正在通过WebVPN接口提取课表...");
      final cookie = await _getCookieString();
      
      String? html;
      String? semesterId;
      
      // Attempt 1: New System (Student)
      try {
        html = await _academicClient.fetchHtmlWithCookie(
          "$targetBase/student/for-std/course-table", 
          cookie
        );
        
        // Extract semester ID from JS: var semesters = JSON.parse('...');
        if (html != null) {
           final semMatch = RegExp(r"var semesters = JSON\.parse\('([^']*)'\)").firstMatch(html);
           if (semMatch != null) {
              String semJsonStr = semMatch.group(1) ?? "";
              semJsonStr = semJsonStr.replaceAll(r'\"', '"'); // Unescape
              List<dynamic> sems = jsonDecode(semJsonStr);
              // Pick the largest ID (latest semester)
              if (sems.isNotEmpty) {
                 sems.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
                 semesterId = sems.first['id'].toString();
                 debugPrint("Detected Semester ID: $semesterId");
              }
           }
        }
      } catch (e) {
        debugPrint("New system check failed: $e");
      }

      final newTable = ScheduleTable(
          id: DateTime.now().millisecondsSinceEpoch,
          tableName: "Web导入课表",
          startDate: "2024-09-02", 
          maxWeek: 20
      );
      
      final parser = CourseParser();
      List<dynamic> courses = [];

      // If found semesterId, fetch JSON data
      if (semesterId != null) {
         try {
           final jsonUrl = "$targetBase/student/for-std/course-table/semester/$semesterId/print-data?semesterId=$semesterId&hasExperiment=true";
           final jsonStr = await _academicClient.fetchHtmlWithCookie(jsonUrl, cookie);
           if (jsonStr != null && jsonStr.startsWith('{')) {
              courses = parser.parse(jsonStr, newTable.id);
              _showSnack("检测到新系统数据");
           }
         } catch(e) {
           debugPrint("JSON Fetch failed: $e");
         }
      }

      // Fallback: Parse HTML (Old EAMS or whatever html we have)
      if (courses.isEmpty) {
        if (html == null || !html.contains("table")) {
           // Try fetching old eams if new one failed completely
           html = await _academicClient.fetchHtmlWithCookie(
             "$targetBase/eams/courseTableForStd.action", 
             cookie
           );
        }
        if (html != null && html.isNotEmpty) {
             courses = parser.parse(html, newTable.id);
        }
      }
      
      if (courses.isEmpty) {
        _showSnack("未检测到有效课表数据");
        return;
      }

      await ScheduleDataService.addScheduleTable(newTable);
      for (var c in courses) {
        // Cast dynamic to Course
        await ScheduleDataService.addCourse(c as dynamic); 
      }
      
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
             ElevatedButton.icon(
                 onPressed: _extractCourse, 
                 icon: const Icon(Icons.calendar_month),
                 label: const Text("课表")
             ),
             ElevatedButton.icon(
                 onPressed: _extractScore, 
                 icon: const Icon(Icons.score),
                 label: const Text("成绩")
             ),
             ElevatedButton.icon(
                 onPressed: _extractExam, 
                 icon: const Icon(Icons.assignment),
                 label: const Text("考试")
             ),
             ElevatedButton.icon(
                 onPressed: _extractInfo, 
                 icon: const Icon(Icons.person),
                 label: const Text("信息")
             ),
          ],
        ),
      ),
    );
  }
}
