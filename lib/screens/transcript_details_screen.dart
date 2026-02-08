import 'package:flutter/material.dart';

class TranscriptDetailsScreen extends StatelessWidget {
  const TranscriptDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('成绩说明'),
        centerTitle: true,
      ),
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
            const SizedBox(height: 24),
            _buildSection(
              context,
              icon: Icons.recommend_rounded,
              title: '为何推荐 PDF 导入？',
              content:
                  '我们强烈推荐使用“从PDF导入”功能，原因如下：\n\n1. 无需评教即可查看：\n通常情况下，教务系统要求先完成评教才能查看成绩，但通过生成的 PDF 成绩单往往可以直接包含已出的成绩，绕过评教限制。\n\n2. 数据准确性高：\nPDF 文件为学校系统生成的正式文档，权威保证。\n\n但是，PDF 文件并不包含挂科、重修、缓考等情况，仅能显示所有已通过的成绩。且由于排版问题，某些课程可能无法正确解析。将在未来修复',
              color: Colors.blue,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'MySUES',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
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
            color: Colors.black.withOpacity(0.05),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
