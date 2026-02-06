import 'package:flutter/material.dart';

class OpenSourceLicenseScreen extends StatelessWidget {
  const OpenSourceLicenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('开源致谢'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '字体资源',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
            // You can add more open source libraries here if needed in the future
          ],
        ),
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
          style: const TextStyle(fontSize: 13),
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
