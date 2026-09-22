import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mysues/screens/about/user_agreement_screen.dart';
import 'package:mysues/screens/about/privacy_policy_screen.dart';
import 'package:mysues/screens/about/author_screen.dart';
import 'package:mysues/screens/about/acknowledgements_screen.dart';
import 'package:mysues/screens/about/open_source_license_screen.dart';
import 'package:mysues/screens/about/egg_screen.dart';
import 'package:mysues/screens/main_entry_screen.dart';
import 'package:mysues/services/app_integrity_service.dart';
import 'package:mysues/l10n/l10n.dart';
import 'package:mysues/widgets/app_integrity_warning.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _tapCount = 0;
  DateTime? _lastTapTime;
  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _versionLabel = _formatVersion(info));
  }

  /// Show the build number only when it adds information. If pubspec.yaml is
  /// ever released without a `+build` suffix, iOS reports CFBundleVersion as
  /// the version name itself, so printing both would read "1.2.1 (1.2.1)".
  static String _formatVersion(PackageInfo info) {
    final build = info.buildNumber;
    return build.isEmpty || build == info.version
        ? 'Version ${info.version}'
        : 'Version ${info.version} ($build)';
  }

  void _onIconTap() {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds > 500) {
      _tapCount = 0;
    }
    _lastTapTime = now;
    _tapCount++;

    if (_tapCount >= 5) {
      _tapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EggScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.about), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _onIconTap,
                  child: Image.asset(
                    'assets/images/MySUES.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.appTitle,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _versionLabel ?? '',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => openOfficialDownloadPage(context),
                  child: Text(
                    context.l10n.checkForUpdates,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          if (AppIntegrityService().requiresWarning) ...[
            const SizedBox(height: 24),
            const AppIntegrityWarningCard(),
          ],
          const SizedBox(height: 40),

          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _buildOptionItem(
                  context,
                  context.l10n.userAgreement,
                  const UserAgreementScreen(),
                ),
                const Divider(height: 1, indent: 16),
                _buildOptionItem(
                  context,
                  context.l10n.privacyPolicy,
                  const PrivacyPolicyScreen(),
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  title: Text(context.l10n.tutorial),
                  trailing: const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onTap: () => MainEntryScreen.showOnboarding(context),
                ),
                const Divider(height: 1, indent: 16),
                _buildOptionItem(
                  context,
                  context.l10n.openSource,
                  const OpenSourceLicenseScreen(),
                ),
                const Divider(height: 1, indent: 16),
                _buildOptionItem(
                  context,
                  context.l10n.author,
                  const AuthorScreen(),
                ),
                const Divider(height: 1, indent: 16),
                _buildOptionItem(
                  context,
                  context.l10n.acknowledgements,
                  const AcknowledgementsScreen(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),
          Column(
            children: [
              const Text(
                'Copyright © 2026 HsxMark',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openIcpFiling,
                child: const Text(
                  '鲁ICP备2026043859号-2A',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openIcpFiling() async {
    final Uri uri = Uri.parse('https://beian.miit.gov.cn/');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not open MIIT ICP filing query page: $uri');
    }
  }

  Widget _buildOptionItem(BuildContext context, String title, Widget page) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }
}
