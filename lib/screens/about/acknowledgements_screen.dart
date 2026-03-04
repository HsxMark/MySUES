import 'package:flutter/material.dart';

class AcknowledgementsScreen extends StatelessWidget {
  const AcknowledgementsScreen({super.key});

  static const List<String> _sponsors = [
    'WJY',
    '寰宇BH4HAP',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('鸣谢'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.favorite, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              '感谢以下用户对本项目的赞助',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '排名不分先后',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: _sponsors.map((name) {
                return Chip(
                  label: Text(name),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
