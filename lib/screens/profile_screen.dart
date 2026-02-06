import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysues/models/student_info.dart';
import 'package:mysues/screens/profile_edit_screen.dart';
import 'package:mysues/screens/settings/settings_screen.dart';
import 'package:mysues/screens/about_screen.dart';
import 'package:mysues/screens/login_webview_screen.dart'; // Import this
import '../services/networking/academic_client.dart';
import '../services/parsers/course_parser.dart';
import '../services/parsers/score_parser.dart';
import '../services/parsers/exam_parser.dart';
import '../services/schedule_service.dart';
import '../services/score_service.dart';
import '../services/exam_service.dart';
import '../models/schedule_table.dart';
import '../models/course.dart'; // Ensure Course is imported

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
 
class _ProfileScreenState extends State<ProfileScreen> {
  // Mock data removed. Initialized to null.
  String? _studentId;
  String? _name; 
  int _currentWeek = 1; // Default
  int _totalWeeks = 20; // Default

  File? _avatarFile;
  String? _major;
  String? _nickname;
  String? _lastSyncTime;
  
  static const String _studentIdKey = 'student_id';
  static const String _avatarPrefsKey = 'user_avatar_path';
  static const String _majorPrefsKey = 'user_major';
  static const String _nicknamePrefsKey = 'user_nickname';
  static const String _lastSyncTimeKey = 'last_sync_time_academic';
  
  bool get _isLoggedIn => _studentId != null && _studentId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _studentId = prefs.getString(_studentIdKey);
      _nickname = prefs.getString(_nicknamePrefsKey);
      _name = _nickname; // Use nickname as name for now, or fetch separate 'real_name' if saved
      // Usually nickname is user set alias, name is real name. 
      // If we extract name from system, we might want to save to 'user_nickname' or a new 'real_name'.
      // StudentInfoParser creates 'name'. LoginWebview saves to 'user_nickname'.
      // So _nickname matches extracted name.
      
      _major = prefs.getString(_majorPrefsKey);
      _lastSyncTime = prefs.getString(_lastSyncTimeKey);
      
      // Calculate week? 
      // Need a way to set start date. For now keeping defaults or logic based on saved start date?
      // ScheduleDataService could provide current week.
      // _currentWeek = await ScheduleDataService.calculateCurrentWeek();
      // For now, leave defaults as placeholders until Schedule logic is fully linked.
    });

    // Load Avatar
    final path = prefs.getString(_avatarPrefsKey);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        setState(() {
          _avatarFile = file;
        });
      }
    } else {
        setState(() {
          _avatarFile = null;
        });
    }

    // Load Nickname
    setState(() {
      _nickname = prefs.getString(_nicknamePrefsKey);
    });

    // Load Major
    final savedMajor = prefs.getString(_majorPrefsKey);
    if (savedMajor != null && savedMajor.isNotEmpty) {
      setState(() {
        _major = savedMajor;
      });
    } else if (_studentId != null) {
      // Fallback to calculation from ID if not saved
      final info = StudentInfoHelper.parseStudentId(_studentId!);
      setState(() {
        _major = info['major'] ?? '未知';
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_studentId == null) return;
    
    // Calculate default major to pass if not set
    final info = StudentInfoHelper.parseStudentId(_studentId!);
    final defaultMajor = info['major'] ?? '未知';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(
          name: _name ?? '未知',
          studentId: _studentId!,
          defaultMajor: defaultMajor,
        ),
      ),
    );
    
    // Reload data when returning
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildUserInfoSection(context),
          const SizedBox(height: 16),
          // Only show progress if logged in
           if (_isLoggedIn) ...[
             _buildProgressSection(context),
             const SizedBox(height: 16),
           ],
          _buildConnectionStatusCard(context),
          const SizedBox(height: 16),
          const _SettingsTile(),
          const _AboutTile(),
          const SizedBox(height: 48),
          const _Footer(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context) {
    if (!_isLoggedIn || _studentId == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              '请连接教务系统同步信息',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final info = StudentInfoHelper.parseStudentId(_studentId!);

    return GestureDetector(
      onTap: _navigateToEditProfile,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                    child: _avatarFile == null
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              'assets/images/sues-single.svg',
                              fit: BoxFit.contain,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_nickname != null && _nickname!.isNotEmpty) ? _nickname! : (_name ?? '未知'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _studentId!,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCompactInfoItem('年级', info['grade'] ?? '未知'),
                  _buildCompactInfoItem('专业', _major ?? info['major'] ?? '未知'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    // Semester Progress
    final double semesterProgress = _currentWeek / _totalWeeks;
    final int semesterPercentage = (semesterProgress * 100).round();

    // University Progress Calculation
    String universityProgress = "0%";
    if (_studentId != null && _studentId!.length >= 6) {
      try {
        final yearStr = _studentId!.substring(4, 6);
        final int entranceYear = 2000 + (int.tryParse(yearStr) ?? 0);
        final int currentYear = 2026;
        final int currentMonth = 2; // Feb

        // Calculate current semester (1-based)
        // If Sept (9) or later: (Current - Entrance) * 2 + 1
        // If before Sept: (Current - Entrance) * 2
        // Example: Entr 2023. Curr 2026-02. Diff=3. Sem = 3*2 = 6.
        int currentSemester = (currentYear - entranceYear) * 2;
        if (currentMonth >= 9) {
          currentSemester += 1;
        }

        // Total semesters for 4 years = 8
        // Progress = (Finished Semesters + Current Semester Fraction) / Total
        // Finished Semesters = CurrentSemester - 1
        double completedSemesters = (currentSemester - 1).toDouble();
        
        // Add current semester fraction
        completedSemesters += semesterProgress;

        double progress = completedSemesters / 8.0;
        
        // Clamp to 0-1 range for sanity, or allow >100% if delayed? 
        // Let's clamp to 0 if negative (invalid) but allow >100% 
        if (progress < 0) progress = 0;
        
        universityProgress = "${(progress * 100).round()}%";
      } catch (e) {
        universityProgress = "Err";
      }
    }

    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    '本学期进度',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: semesterProgress,
                        backgroundColor: Colors.grey[200],
                        strokeWidth: 8,
                      ),
                      Text(
                        '${_currentWeek}/${_totalWeeks}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$semesterPercentage%', // Display rounded percentage if needed or keep style simple
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '大学进度',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    universityProgress,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Text(
                    '(肆年制)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatusCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _navigateToWebLogin, // Changed to navigate to WebLogin
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sync_alt, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        '教务连接',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_lastSyncTime != null) ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (_lastSyncTime != null) ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3)
                      ),
                    ),
                    child: Text(
                      (_lastSyncTime != null) ? '已连接' : '未连接',
                      style: TextStyle(
                        color: (_lastSyncTime != null) ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '上次同步时间',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    _lastSyncTime ?? '点击同步数据',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      fontFamily: Platform.isIOS ? 'Courier' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToWebLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginWebviewScreen()),
    );
    // Refresh timestamp after return specific key update
    _loadData(); 
  }
} // End of class


class _SettingsTile extends StatelessWidget {
  const _SettingsTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.settings_outlined),
      title: const Text('设置'),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
      },
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('关于'),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
      },
    );
  }
}


class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '苏伊士 by HsxMark',
        style: TextStyle(
          color: Colors.grey[300],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
