import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mysues/services/theme_service.dart';
import 'package:mysues/widgets/liquid_glass_bottom_bar.dart';
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
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        final useLiquidGlass = ThemeService().liquidGlassEnabled;
        final bgPath = ThemeService().backgroundImagePath;
        final hasBg = bgPath != null;

        Widget scaffold = Scaffold(
          extendBody: useLiquidGlass,
          backgroundColor: hasBg ? Colors.transparent : null,
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: useLiquidGlass 
            ? LiquidGlassBottomBar(
                selectedIndex: _currentIndex,
                onTabSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                tabs: const [
                  LiquidGlassBottomBarTab(
                    icon: Icons.calendar_month,
                    label: '课程表',
                  ),
                  LiquidGlassBottomBarTab(
                    icon: Icons.description,
                    label: '成绩单',
                  ),
                  LiquidGlassBottomBarTab(
                    icon: Icons.edit_calendar,
                    label: '考试信息',
                  ),
                  LiquidGlassBottomBarTab(
                    icon: Icons.person,
                    label: '我',
                  ),
                ],
              )
            : BottomNavigationBar(
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

        if (!hasBg) return scaffold;

        // Wrap with Theme override so child Scaffolds inherit transparent background
        scaffold = Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: Colors.transparent,
          ),
          child: scaffold,
        );

        final bgOpacity = ThemeService().backgroundOpacity;

        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: bgOpacity,
              child: Image.file(
                File(bgPath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
              ),
            ),
            scaffold,
          ],
        );
      },
    );
  }
}
