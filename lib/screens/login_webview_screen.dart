import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import '../services/networking/academic_client.dart';
import '../services/webvpn/fetch_course_service.dart';
import '../services/webvpn/fetch_info_service.dart';
import '../services/webvpn/fetch_score_service.dart';
import '../services/webvpn/fetch_exam_service.dart';
import '../models/exam.dart';
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
  bool _hasStartedAutoFetch = false;
  bool _isDataChanged = false;
  
  bool _isFetchingInfo = false; 

  String _currentStep = '请登录 教务系统';
  
  
  static const String initialUrl = 'https://webvpn.sues.edu.cn/login';

  
  
  static const String _academicHex = '77726476706e69737468656265737421faef478b69237d556d468ca88d1b203b';

  
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
      
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            
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
            
            if (error.description.contains("CACHE_MISS")) {
               debugPrint("Encountered ERR_CACHE_MISS. Suggest user to go back or refresh manually.");
               
            }
            if (mounted) {
               setState(() => _isLoading = false);
            }
          },
        ),
      );
    
    
    await _controller.clearCache();
    await _controller.clearLocalStorage();
    
    if (mounted) {
      _controller.loadRequest(Uri.parse(initialUrl));
    }
  }

  
  void _detectBaseUrl(String url) {
    debugPrint("Checking URL: $url");
    final uri = Uri.parse(url);
    if (uri.host == 'webvpn.sues.edu.cn') {
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'https') {
        final hexKey = segments[1];
        
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
    if (url != null && (url.contains("/student/home") || url.contains("/student/for-std/course-table"))) {
       
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
    
    
    
    try {
      final String result = await _controller.runJavaScriptReturningResult('document.cookie') as String;
      return _decodeJsString(result);
    } catch (e) {
      return "";
    }
  }

  Future<void> _startAutoFetch() async {
    
    if (_hasStartedAutoFetch) return;
    _hasStartedAutoFetch = true;

    try {
      String targetBase = _detectedVpnBase ?? "https://webvpn.sues.edu.cn/https/$_academicHex";
      
      
      final currentUrl = await _controller.currentUrl();
      if (currentUrl == null || !currentUrl.contains("student/for-std/course-table")) {
         setState(() => _currentStep = "正在跳转到课表页面...");
         final courseUrl = "$targetBase/student/for-std/course-table";
         await _controller.loadRequest(Uri.parse(courseUrl));
         
         
         int retries = 0;
         while(retries < 10) {
            await Future.delayed(const Duration(seconds: 1));
            final url = await _controller.currentUrl();
            if (url != null && url.contains("course-table")) break;
            retries++;
         }
      }

      setState(() => _currentStep = "正在获取学期列表...");
      
      
      List<String> semesterIds = [];
      int retryCount = 0;
      while (retryCount < 15) {
        semesterIds = await FetchCourseService.fetchSemesterIds(_controller);
        if (semesterIds.isNotEmpty) break;
        await Future.delayed(const Duration(seconds: 1));
        retryCount++;
      }

      if (semesterIds.isEmpty) {
        _showSnack("未找到学期列表，请重试");
        setState(() {
           _currentStep = "抓取失败，请重试"; 
           _hasStartedAutoFetch = false; 
        });
        return;
      }

      
      
      if (_isFetchingInfo) {
         
         setState(() => _currentStep = "正在提取个人信息...");
         final info = await FetchInfoService.fetchStudentInfo(_controller, targetBase);
         
         if (info != null && info.isNotEmpty) {
            await FetchInfoService.saveStudentInfo(info);
            if (!mounted) return;
            String msg = "已更新: ${info['name']}";
            if (info['code'] != null) msg += " (${info['code']})";
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
            _recordSyncTime();
         } else {
            if (!mounted) return;
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("未能提取到有效的个人信息")));
         }
         
         
         
         
         
         
         if (!mounted) return;
         Navigator.pop(context, true);
         return;
      }
      

      if (!mounted) return;
      
      
      
      
      setState(() => _currentStep = "正在解析学期信息 (${semesterIds.length}个)...");
      
      List<Map<String, dynamic>> semesterOptions = [];
      for (var id in semesterIds) {
         final info = await FetchCourseService.fetchSemesterInfo(_controller, targetBase, id);
         if (info != null) {
            semesterOptions.add({
              'id': id,
              'name': info['nameZh'] ?? '未知学期',
              'info': info
            });
         } else {
            semesterOptions.add({'id': id, 'name': '学期 $id', 'info': {}});
         }
      }

      if (!mounted) return;
      
      final selectedMap = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("请选择导入学期"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: semesterOptions.length,
              itemBuilder: (ctx, index) {
                final item = semesterOptions[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text("ID: ${item['id']}"),
                  onTap: () => Navigator.pop(ctx, item),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text("取消"),
            )
          ],
        ),
      );

      if (selectedMap == null) {
         setState(() {
           _currentStep = "用户取消操作";
           _hasStartedAutoFetch = false;
         });
         return;
      }

      final semesterId = selectedMap['id'] as String;
      final info = selectedMap['info'] as Map<String, dynamic>;
      final semesterName = selectedMap['name'] as String;

      setState(() => _currentStep = "正在抓取 $semesterName 课表...");

      
      final courseData = await FetchCourseService.fetchCourseData(_controller, targetBase, semesterId);
      if (courseData == null) {
         _showSnack("抓取课表数据失败");
         setState(() => _hasStartedAutoFetch = false);
         return;
      }

      
      final startDateStr = info['startDate'] as String? ?? "2024-09-01";
      final table = ScheduleTable(
        tableName: semesterName,
        nodes: 15,
        startDate: startDateStr,
      );
      
      
      await ScheduleDataService.addScheduleTable(table);
      
      
      
      setState(() => _currentStep = "正在保存课程数据...");
      final courses = FetchCourseService.parseCourseData(courseData, table.id);
      
      if (courses.isEmpty) {
        _showSnack("未能解析出任何课程");
      } else {
        
        
        
        var allCourses = await ScheduleDataService.loadCourses();
        
        
        int maxId = 0;
        if (allCourses.isNotEmpty) {
           maxId = allCourses.map((e) => e.id).reduce((a, b) => a > b ? a : b);
        }
        
        for (var c in courses) {
           maxId++;
           c.id = maxId;
           allCourses.add(c);
        }
        await ScheduleDataService.saveCourses(allCourses);
        
        
        await ScheduleDataService.setCurrentTableId(table.id);
        
        
        final uniqueCount = courses.map((c) => c.courseName).toSet().length;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("成功导入 $uniqueCount 门课程 (共 ${courses.length} 条记录)")));
        _recordSyncTime();

        
        
        
        
        
        
        Navigator.pop(context, true); 
      }

    } catch (e) {
      debugPrint("Auto fetch error: $e");
      if (mounted) _showSnack("发生错误: $e");
      setState(() => _hasStartedAutoFetch = false);
    }
  }






  Future<void> _extractScore() async {
    try {
      String targetBase = _detectedVpnBase ?? "https://webvpn.sues.edu.cn/https/$_academicHex";
      
      _showSnack("正在获取基础数据...");
      
      
      final currentUrl = await _controller.currentUrl();
      if (currentUrl == null || !currentUrl.contains("student/for-std/course-table")) {
         _showSnack("跳转到课表页面以获取数据...");
         String courseUrl = "$targetBase/student/for-std/course-table";
         await _controller.loadRequest(Uri.parse(courseUrl));
         
         
         int retries = 0;
         while(retries < 15) {
            await Future.delayed(const Duration(milliseconds: 1000));
            final url = await _controller.currentUrl();
            if (url != null && url.contains("course-table")) break;
            retries++;
         }
      }

      
      List<String> semesterIds = []; 
      int retryCount = 0;
      while (retryCount < 10) {
        semesterIds = await FetchCourseService.fetchSemesterIds(_controller);
        if (semesterIds.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: 500));
        retryCount++;
      }
      
      if (semesterIds.isEmpty) throw "无法获取学期列表，请重试";

      
      String? studentId;
      _showSnack("正在解析...");
      
      
      final latestSemester = semesterIds.first;
      final courseData = await FetchCourseService.fetchCourseData(_controller, targetBase, latestSemester);
      
      if (courseData != null && courseData['studentTableVms'] != null) {
        final vms = courseData['studentTableVms'] as List;
        if (vms.isNotEmpty) {
            final vm = vms[0];
            if (vm['id'] != null) {
              studentId = vm['id'].toString(); 

              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_internal_id', studentId);
              
              if (vm['code'] != null) {
                await prefs.setString('student_id', vm['code'].toString());
              }
              if (vm['name'] != null) {
                await prefs.setString('user_nickname', vm['name'].toString());
              }
            }
        }
      }
      
      if (studentId == null) throw "无法从课表数据中解析...";

      _showSnack("正在提取成绩 (共${semesterIds.length}个学期)...");
      
      
      final scores = await FetchScoreService.fetchAllScores(
          _controller, targetBase, studentId, semesterIds);
      
      if (scores.isEmpty) {
        final msg = "未检测到成绩数据 (学期数:${semesterIds.length})";
        debugPrint(msg);
        _showSnack(msg);
        return;
      }
      
      await ScoreService.saveScores(scores);
      
      final now = DateTime.now();
      final timeStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      await ScoreService.saveImportInfo(timeStr, "教务系统");

      _showSnack("成功导入 ${scores.length} 条成绩记录！");
      _isDataChanged = true;
      _recordSyncTime();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Extract score error: $e");
      _showSnack("提取失败: $e");
    }
  }

  Future<void> _extractExam() async {
    try {
      String targetBase = _detectedVpnBase ?? "https://webvpn.sues.edu.cn/https/$_academicHex";

      
      final currentUrl = await _controller.currentUrl();
      if (currentUrl == null || !currentUrl.contains("student/for-std/course-table")) {
        setState(() => _currentStep = "正在跳转到教务系统...");
        String courseUrl = "$targetBase/student/for-std/course-table";
        await _controller.loadRequest(Uri.parse(courseUrl));

        int retries = 0;
        while (retries < 15) {
          await Future.delayed(const Duration(milliseconds: 1000));
          final url = await _controller.currentUrl();
          if (url != null && url.contains("course-table")) break;
          retries++;
        }
      }

      
      setState(() => _currentStep = "正在等待页面加载...");
      List<String> semesterIds = [];
      int retryCount = 0;
      while (retryCount < 30) {
        semesterIds = await FetchCourseService.fetchSemesterIds(_controller);
        if (semesterIds.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: 1000));
        retryCount++;
      }

      if (semesterIds.isEmpty) {
        _showSnack("页面未就绪，请重试");
        setState(() => _currentStep = "页面加载超时，请重试");
        return;
      }

      
      setState(() => _currentStep = "正在解析学生信息...");
      String? studentId;
      final prefs = await SharedPreferences.getInstance();
      studentId = prefs.getString('user_internal_id');

      if (studentId == null || studentId.isEmpty) {
        final latestSemester = semesterIds.first;
        final courseData = await FetchCourseService.fetchCourseData(_controller, targetBase, latestSemester);

        if (courseData != null && courseData['studentTableVms'] != null) {
          final vms = courseData['studentTableVms'] as List;
          if (vms.isNotEmpty) {
            final vm = vms[0];
            if (vm['id'] != null) {
              studentId = vm['id'].toString();
              await prefs.setString('user_internal_id', studentId);
              if (vm['code'] != null) {
                await prefs.setString('student_id', vm['code'].toString());
              }
              if (vm['name'] != null) {
                await prefs.setString('user_nickname', vm['name'].toString());
              }
            }
          }
        }
      }

      if (studentId == null || studentId.isEmpty) {
        _showSnack("无法获取学生信息，请重试");
        setState(() => _currentStep = "获取学生信息失败");
        return;
      }

      
      List<Exam> exams = [];
      for (int attempt = 1; attempt <= 3; attempt++) {
        setState(() => _currentStep = "正在提取考试安排...${attempt > 1 ? ' (第${attempt}次尝试)' : ''}");
        exams = await FetchExamService.fetchExams(
          _controller, targetBase, studentId: studentId);
        if (exams.isNotEmpty) break;
        if (attempt < 3) {
          setState(() => _currentStep = "未获取到数据，等待重试...");
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      if (exams.isEmpty) {
        _showSnack("未检测到考试数据");
        setState(() => _currentStep = "未找到考试数据");
        return;
      }

      await ExamService.saveExams(exams);
      String msg = "成功导入 ${exams.length} 条考试记录！";
      _showSnack(msg);
      setState(() => _currentStep = msg);

      _isDataChanged = true;
      _recordSyncTime();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Extract Exam Error: $e");
      _showSnack("提取失败: $e");
      setState(() => _currentStep = "提取失败，请重试");
    }
  }

  Future<void> _extractInfo() async {
    
    
    
    try {
       String targetBase = _detectedVpnBase ?? "https://webvpn.sues.edu.cn/https/$_academicHex";
       
       
       
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
      
      return jsonDecode(jsInfo).toString();
    } catch (e) {
      debugPrint("JSON Decode error: $e");
      
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _isDataChanged);
        return false;
      },
      child: Scaffold(
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
                            _isFetchingInfo = true;
                            _startAutoFetch();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.calendar_month),
                          title: const Text("提取课表"),
                          onTap: () {
                            Navigator.pop(context);
                            _isFetchingInfo = false; 
                            _startAutoFetch();
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
      ),
    );
  }
}
