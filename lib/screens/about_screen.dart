import 'package:flutter/material.dart';
import 'package:mysues/screens/about/user_agreement_screen.dart';
import 'package:mysues/screens/about/privacy_policy_screen.dart';
import 'package:mysues/screens/about/sponsor_screen.dart';
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
                    'assets/images/example/MySUES-1024x1024@1x.png',
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
                  'Version 1.2.0-Alpha',
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
                  const SponsorScreen(),
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
          const Center(
            child: Text(
              'Copyright © 2026 HsxMark',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
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
