import 'package:flutter/material.dart';

class AcknowledgementsScreen extends StatelessWidget {
  const AcknowledgementsScreen({super.key});

  static const List<String> _sponsors = [
    'ethene',
    'xi08',
    'WJY',
    '寰宇BH4HAP',
    '楚龙',
    'a1375625918',
    '想吸夜魔内陷乳'
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '赞助者',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '衷心感谢以下用户对本项目的赞助（排名不分先后）',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
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
                  children: List.generate(_sponsors.length * 2 - 1, (index) {
                    if (index.isOdd) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Divider(height: 1),
                      );
                    }
                    final sponsor = _sponsors[index ~/ 2];
                    return Center(
                      child: Text(sponsor, style: const TextStyle(fontSize: 15)),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
