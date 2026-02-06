import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysues/screens/about/user_agreement_screen.dart';
import 'package:mysues/screens/about/privacy_policy_screen.dart';
import 'package:mysues/screens/about/feature_intro_screen.dart';
import 'package:mysues/screens/about/changelog_screen.dart';
import 'package:mysues/screens/about/sponsor_screen.dart';
import 'package:mysues/screens/about/open_source_license_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/MySUES-1024x1024@1x.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                const Text(
                  '苏伊士',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _buildOptionItem(context, '用户协议', const UserAgreementScreen()),
                const Divider(height: 1, indent: 16),
                _buildOptionItem(context, '隐私政策', const PrivacyPolicyScreen()),
                const Divider(height: 1, indent: 16),
                _buildOptionItem(context, '功能介绍', const FeatureIntroScreen()),
                const Divider(height: 1, indent: 16),
                _buildOptionItem(context, '版本更新', const ChangelogScreen()),
                const Divider(height: 1, indent: 16),
                _buildOptionItem(context, '开源致谢', const OpenSourceLicenseScreen()),
                const Divider(height: 1, indent: 16),
                _buildOptionItem(context, '作者', const SponsorScreen()),
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}
