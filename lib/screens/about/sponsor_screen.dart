import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mysues/l10n/legacy_text.dart';

class SponsorScreen extends StatelessWidget {
  const SponsorScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const LText('作者')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              child: LText('H', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 16),
            const LText(
              'HsxMark',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const LText('独立开发者', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.code, size: 28),
              title: const LText('GitHub'),
              subtitle: const LText('github.com/HsxMark'),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () => _launchUrl('https://github.com/HsxMark'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
