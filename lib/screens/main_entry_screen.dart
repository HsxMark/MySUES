import 'package:flutter/material.dart';
import 'schedule_screen.dart';
import 'transcript_screen.dart';
import 'exam_info_screen.dart';
import 'profile_screen.dart';

class MainEntryScreen extends StatefulWidget {
  const MainEntryScreen({super.key});

  @override
  State<MainEntryScreen> createState() => _MainEntryScreenState();
}

class _MainEntryScreenState extends State<MainEntryScreen> {
  int _currentIndex = 0;
  
  // 页面列表
  final List<Widget> _pages = [
    const ScheduleScreen(),
    const TranscriptScreen(),
    const ExamInfoScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // 超过3个item时需要这个，或者设置selectedItemColor等
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month), // 或者 table_chart
            label: '课程表',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description), // 或者 assignment_outlined
            label: '成绩单',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_calendar), // 或者 event_note
            label: '考试信息',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我',
          ),
        ],
      ),
    );
  }
}
