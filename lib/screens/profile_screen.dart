import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysues/models/student_info.dart';
import 'package:mysues/screens/profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final bool isLoggedIn = true; // TODO: Replace with actual auth state
  final String? studentId = "051523117"; // TODO: Replace with actual user data
  final String? name = "王俊桦"; // TODO: Replace with actual user data
  final int currentWeek = 6; // TODO: Replace with actual data
  final int totalWeeks = 20; // TODO: Replace with actual data

  File? _avatarFile;
  String? _major;
  String? _nickname;
  
  static const String _avatarPrefsKey = 'user_avatar_path';
  static const String _majorPrefsKey = 'user_major';
  static const String _nicknamePrefsKey = 'user_nickname';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
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
    } else if (studentId != null) {
      // Fallback to calculation from ID if not saved
      final info = StudentInfoHelper.parseStudentId(studentId!);
      setState(() {
        _major = info['major'] ?? '未知';
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (studentId == null) return;
    
    // Calculate default major to pass if not set
    final info = StudentInfoHelper.parseStudentId(studentId!);
    final defaultMajor = info['major'] ?? '未知';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(
          name: name ?? '未知',
          studentId: studentId!,
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
          _buildProgressSection(context),
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
    if (!isLoggedIn || studentId == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              '请登录查看',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final info = StudentInfoHelper.parseStudentId(studentId!);

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
                        (_nickname != null && _nickname!.isNotEmpty) ? _nickname! : (name ?? '未知'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        studentId!,
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
    final double semesterProgress = currentWeek / totalWeeks;
    final int semesterPercentage = (semesterProgress * 100).round();

    // University Progress Calculation
    String universityProgress = "0%";
    if (studentId != null && studentId!.length >= 6) {
      try {
        final yearStr = studentId!.substring(4, 6);
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
                        '${currentWeek}/${totalWeeks}',
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
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.settings_outlined),
      title: const Text('设置'),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // TODO: Navigate to settings screen
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
        // TODO: Navigate to about screen
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
