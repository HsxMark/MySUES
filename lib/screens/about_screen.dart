import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

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
                Container(
                   width: 80,
                   height: 80,
                   decoration: BoxDecoration(
                     color: Theme.of(context).primaryColor.withOpacity(0.1),
                     shape: BoxShape.circle,
                   ),
                   child: Icon(Icons.school, size: 40, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 16),
                const Text(
                  '我的课表',
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
          
          const Text(
            '字体致谢',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildFontInfo(
                     context,
                     'HarmonyOS Sans', 
                     '华为软件技术有限公司', 
                     '遵循 HarmonyOS Sans 字体授权协议'
                   ),
                   const Padding(
                     padding: EdgeInsets.symmetric(vertical: 12.0),
                     child: Divider(height: 1),
                   ),
                   _buildFontInfo(
                     context,
                     'MiSans',
                     '小米科技有限责任公司',
                     '遵循 MiSans 字体知识产权许可协议'
                   ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text(
            '开发者',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
             child: ListTile(
               leading: const Icon(Icons.code, size: 32),
               title: const Text('HsxMark'),
               subtitle: const Text('github.com/HsxMark'),
               trailing: const Icon(Icons.open_in_new, size: 16),
               onTap: () => _launchUrl('https://github.com/HsxMark'),
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

  Widget _buildFontInfo(BuildContext context, String name, String provider, String license) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('免费商用', style: TextStyle(fontSize: 10, color: Colors.blue)),
            )
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '由 $provider 提供',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          license,
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}
