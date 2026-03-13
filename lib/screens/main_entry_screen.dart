import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysues/services/theme_service.dart';
import 'package:mysues/widgets/liquid_glass_bottom_bar.dart';
import 'schedule_view_container.dart';
import 'transcript_screen.dart';
import 'exam_info_screen.dart';
import 'profile_screen.dart';
import 'about/user_agreement_screen.dart';
import 'about/privacy_policy_screen.dart';
import 'onboarding_screen.dart';

class MainEntryScreen extends StatefulWidget {
  const MainEntryScreen({super.key});

  /// Call this from other screens (e.g. About) to re-show the tutorial.
  static void showOnboarding(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(isReview: true),
      ),
    );
  }

  @override
  State<MainEntryScreen> createState() => _MainEntryScreenState();
}

class _MainEntryScreenState extends State<MainEntryScreen> {
  int _currentIndex = 0;

  // 懒加载：只有被访问过的 Tab 才会真正构建，避免首次进入时同时初始化全部页面
  final List<Widget?> _cachedPages = [null, null, null, null];

  Widget _getPage(int index) {
    _cachedPages[index] ??= switch (index) {
      0 => ScheduleViewContainer(key: ScheduleViewContainer.containerKey),
      1 => const TranscriptScreen(),
      2 => const ExamInfoScreen(),
      3 => const ProfileScreen(),
      _ => const SizedBox.shrink(),
    };
    return _cachedPages[index]!;
  }

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final agreementAccepted = prefs.getBool('agreement_accepted') ?? false;
    if (!agreementAccepted && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAgreementDialog();
      });
    } else {
      // Agreement already accepted — check onboarding
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      if (!onboardingCompleted && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showOnboarding(prefs);
        });
      }
    }
  }

  void _showAgreementDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('用户协议与隐私政策'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('欢迎使用苏伊士（My SUES）。在使用本应用前，请您仔细阅读并同意以下协议：'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.article_outlined, size: 18, color: Theme.of(dialogContext).colorScheme.primary),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(dialogContext).push(
                          MaterialPageRoute(builder: (_) => const UserAgreementScreen()),
                        );
                      },
                      child: Text(
                        '《用户协议》',
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 18, color: Theme.of(dialogContext).colorScheme.primary),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(dialogContext).push(
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                        );
                      },
                      child: Text(
                        '《隐私政策》',
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '重要提示：本产品为公益性质的完全免费产品，若您是通过付费获取本产品那您遭遇了诈骗。',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '若遇到什么问题，请添加QQ群聊：1045770691 反馈问题',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                const Text(
                  '点击「同意并继续」表示您已阅读并同意以上协议。',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  } else {
                    exit(0);
                  }
                },
                child: const Text('不同意'),
              ),
              FilledButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('agreement_accepted', true);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  // Show onboarding after agreement
                  _showOnboarding(prefs);
                },
                child: const Text('同意并继续'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showOnboarding(SharedPreferences prefs) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
    await prefs.setBool('onboarding_completed', true);
  }

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
            children: List.generate(4, (i) {
              if (_cachedPages[i] == null && i != _currentIndex) {
                return const SizedBox.shrink();
              }
              return _getPage(i);
            }),
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
            // Fallback: normal theme background so it never flashes black
            ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
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
