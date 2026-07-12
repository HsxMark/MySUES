import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysues/services/theme_service.dart';
import 'package:mysues/utils/screen_breakpoints.dart';
import 'package:mysues/widgets/liquid_glass_bottom_bar.dart';
import 'package:mysues/l10n/l10n.dart';
import 'schedule_view_container.dart';
import 'transcript_screen.dart';
import 'exam_info_screen.dart';
import 'profile_screen.dart';
import 'about/user_agreement_screen.dart';
import 'about/privacy_policy_screen.dart';
import 'onboarding_screen.dart';
import 'package:mysues/l10n/legacy_text.dart';

class MainEntryScreen extends StatefulWidget {
  const MainEntryScreen({super.key});

  /// Call this from other screens (e.g. About) to re-show the tutorial.
  static void showOnboarding(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingScreen(isReview: true)),
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
      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;
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
            title: LText(dialogContext.l10n.userAgreementAndPrivacy),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LText(dialogContext.l10n.welcomeAgreement),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 18,
                      color: Theme.of(dialogContext).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(dialogContext).push(
                          MaterialPageRoute(
                            builder: (_) => const UserAgreementScreen(),
                          ),
                        );
                      },
                      child: LText(
                        '《${dialogContext.l10n.userAgreement}》',
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
                    Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: Theme.of(dialogContext).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(dialogContext).push(
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                      child: LText(
                        '《${dialogContext.l10n.privacyPolicy}》',
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
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LText(
                          dialogContext.l10n.agreementFraudWarning,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const LText(
                  '若遇到什么问题，请添加QQ群聊：1045770691 反馈问题',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                LText(
                  dialogContext.l10n.agreementConsentHint,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                child: LText(dialogContext.l10n.disagreeAndExit),
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
                child: LText(dialogContext.l10n.agreeAndContinue),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showOnboarding(SharedPreferences prefs) async {
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    await prefs.setBool('onboarding_completed', true);
  }

  Widget _buildLeftNavigationRail(BuildContext context, bool useLiquidGlass) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: useLiquidGlass
          ? theme.colorScheme.surface.withValues(alpha: 0.55)
          : theme.colorScheme.surfaceContainer,
      child: SafeArea(
        right: false,
        left: false,
        bottom: false,
        child: NavigationRail(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          labelType: NavigationRailLabelType.all,
          groupAlignment: -0.85,
          destinations: [
            NavigationRailDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: LText(context.l10n.schedule),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: LText(context.l10n.transcript),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.edit_calendar_outlined),
              selectedIcon: Icon(Icons.edit_calendar),
              label: LText(context.l10n.exams),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: LText(context.l10n.profile),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        final useLiquidGlass = ThemeService().liquidGlassEnabled;
        final bgPath = ThemeService().backgroundImagePath;
        final hasBg = bgPath != null;
        final size = MediaQuery.sizeOf(context);
        final useRightRail =
            ScreenBreakpoints.isLargeDevice(context) &&
            size.width > size.height;

        final pageStack = IndexedStack(
          index: _currentIndex,
          children: List.generate(4, (i) {
            if (_cachedPages[i] == null && i != _currentIndex) {
              return const SizedBox.shrink();
            }
            return _getPage(i);
          }),
        );

        Widget scaffold = Scaffold(
          extendBody: useLiquidGlass && !useRightRail,
          backgroundColor: hasBg ? Colors.transparent : null,
          body: useRightRail
              ? Row(
                  children: [
                    _buildLeftNavigationRail(context, useLiquidGlass),
                    Expanded(child: pageStack),
                  ],
                )
              : pageStack,
          bottomNavigationBar: useRightRail
              ? null
              : (useLiquidGlass
                    ? LiquidGlassBottomBar(
                        selectedIndex: _currentIndex,
                        onTabSelected: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        tabs: [
                          LiquidGlassBottomBarTab(
                            icon: Icons.calendar_month,
                            label: context.l10n.schedule,
                          ),
                          LiquidGlassBottomBarTab(
                            icon: Icons.description,
                            label: context.l10n.transcript,
                          ),
                          LiquidGlassBottomBarTab(
                            icon: Icons.edit_calendar,
                            label: context.l10n.exams,
                          ),
                          LiquidGlassBottomBarTab(
                            icon: Icons.person,
                            label: context.l10n.profile,
                          ),
                        ],
                      )
                    : NavigationBar(
                        selectedIndex: _currentIndex,
                        onDestinationSelected: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        destinations: [
                          NavigationDestination(
                            icon: Icon(Icons.calendar_month_outlined),
                            selectedIcon: Icon(Icons.calendar_month),
                            label: context.l10n.schedule,
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.description_outlined),
                            selectedIcon: Icon(Icons.description),
                            label: context.l10n.transcript,
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.edit_calendar_outlined),
                            selectedIcon: Icon(Icons.edit_calendar),
                            label: context.l10n.exams,
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.person_outline),
                            selectedIcon: Icon(Icons.person),
                            label: context.l10n.profile,
                          ),
                        ],
                      )),
        );

        if (!hasBg) return scaffold;

        // Wrap with Theme override so child Scaffolds inherit transparent background
        scaffold = Theme(
          data: Theme.of(
            context,
          ).copyWith(scaffoldBackgroundColor: Colors.transparent),
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
