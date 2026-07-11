import 'package:flutter/material.dart';
import 'package:mysues/l10n/legacy_text.dart';

class TranscriptDetailsScreen extends StatelessWidget {
  const TranscriptDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const LText('成绩说明'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              icon: Icons.gavel_rounded,
              title: '免责声明',
              content:
                  '本应用提供的成绩计算及绩点统计功能仅供参考。\n\n由于学校教务系统可能会调整计算规则，或者存在特殊课程（如未评教、重修、免修、缓考等）的处理差异，本应用的计算结果可能与官方教务系统存在细微偏差。\n\n请最终以教务系统发布的正式成绩单为准，开发者不对因使用本数据造成的任何问题承担责任。',
              color: Colors.orange,
            ),
            const SizedBox(height: 40),
            Center(
              child: LText(
                'MySUES',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              LText(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LText(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
