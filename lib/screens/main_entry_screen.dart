import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysues/services/app_integrity_service.dart';
import 'package:mysues/services/theme_service.dart';
import 'package:mysues/utils/screen_breakpoints.dart';
import 'package:mysues/widgets/app_integrity_warning.dart';
import 'package:mysues/widgets/liquid_glass_bottom_bar.dart';
import 'package:mysues/l10n/l10n.dart';
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
      MaterialPageRoute(builder: (_) => const OnboardingScreen(isReview: true)),
    );
  }

  @override
  State<MainEntryScreen> createState() => _MainEntryScreenState();
}

/// First-launch consent dialog.
///
/// Consent is given through a checkbox that is intentionally NOT checked by
/// default; "Agree and Continue" stays disabled until the user ticks it, and a
/// separate "Disagree and Exit" path lets the user refuse.
class _AgreementDialog extends StatefulWidget {
  const _AgreementDialog();

  @override
  State<_AgreementDialog> createState() => _AgreementDialogState();
}

class _AgreementDialogState extends State<_AgreementDialog> {
  bool _agreed = false;
  TapGestureRecognizer? _openUserAgreement;
  TapGestureRecognizer? _openPrivacyPolicy;

  @override
  void initState() {
    super.initState();
    _openUserAgreement = TapGestureRecognizer()
      ..onTap = _goToUserAgreement;
    _openPrivacyPolicy = TapGestureRecognizer()
      ..onTap = _goToPrivacyPolicy;
  }

  @override
  void dispose() {
    _openUserAgreement?.dispose();
    _openPrivacyPolicy?.dispose();
    super.dispose();
  }

  void _goToUserAgreement() {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UserAgreementScreen()),
      );
    }
  }

  void _goToPrivacyPolicy() {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
      );
    }
  }

  void _exitApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  /// Renders the consent sentence with the two document titles as tappable
  /// links, e.g. 「我已阅读并同意《用户协议》和《隐私政策》」.
  Widget _buildConsentText() {
    final l10n = context.l10n;
    final uaTitle = l10n.userAgreement;
    final ppTitle = l10n.privacyPolicy;
    final label = l10n.agreementCheckboxLabel;

    final uaStart = label.indexOf(uaTitle);
    final ppStart = uaStart < 0
        ? -1
        : label.indexOf(ppTitle, uaStart + uaTitle.length);
    if (uaStart < 0 || ppStart < 0) {
      // Fallback if the localized label does not embed the doc titles verbatim.
      return Text(label);
    }

    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    final spans = <InlineSpan>[
      TextSpan(text: label.substring(0, uaStart)),
      TextSpan(
        text: uaTitle,
        recognizer: _openUserAgreement,
        style: linkStyle,
      ),
      TextSpan(text: label.substring(uaStart + uaTitle.length, ppStart)),
      TextSpan(
        text: ppTitle,
        recognizer: _openPrivacyPolicy,
        style: linkStyle,
      ),
      TextSpan(text: label.substring(ppStart + ppTitle.length)),
    ];
    return Text.rich(TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(context.l10n.userAgreementAndPrivacy),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.welcomeAgreement),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreed,
                  onChanged: (value) {
                    setState(() => _agreed = value ?? false);
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildConsentText(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                    child: Text(
                      context.l10n.agreementFraudWarning,
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: _exitApp,
            child: Text(context.l10n.disagreeAndExit),
          ),
          FilledButton(
            onPressed: _agreed
                ? () => Navigator.of(context).pop(true)
                : null,
            child: Text(context.l10n.agreeAndContinue),
          ),
        ],
      ),
    );
  }
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStartupFlow();
    });
  }

  Future<void> _runStartupFlow() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    if (AppIntegrityService().requiresWarning) {
      await showAppIntegrityWarningDialog(context, preferences: prefs);
      if (!mounted) return;
    }

    final agreementAccepted = prefs.getBool('agreement_accepted') ?? false;
    if (!agreementAccepted) {
      await _showAgreementDialog(prefs);
    } else {
      // Agreement already accepted — check onboarding
      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;
      if (!onboardingCompleted && mounted) {
        await _showOnboarding(prefs);
      }
    }
  }

  Future<void> _showAgreementDialog(SharedPreferences prefs) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AgreementDialog(),
    );

    if (accepted == true && mounted) {
      await prefs.setBool('agreement_accepted', true);
      await _showOnboarding(prefs);
    }
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
              label: Text(context.l10n.schedule),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: Text(context.l10n.transcript),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.edit_calendar_outlined),
              selectedIcon: Icon(Icons.edit_calendar),
              label: Text(context.l10n.exams),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: Text(context.l10n.profile),
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
