import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '隐私政策',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '''
My SUES 隐私政策

更新日期：2026年2月6日

您的隐私安全对 My SUES 至关重要。My SUES（以下简称“本软件”）是由上海工程技术大学在校学生独立开发的非官方工具软件。本隐私政策详细说明了我们如何收集、使用、存储和保护您的个人信息。请在使用本软件前仔细阅读。

1. 核心原则：数据本地化
我们坚守“数据本地化”原则。**本软件没有任何独立的后端服务器来存储您的个人敏感信息。**

2. 我们收集和处理的信息
为了提供查询服务，本软件需要处理以下信息：
*   **学号与密码**：仅用于验证您的身份并登录学校教务系统。
*   **教务数据**：包括您的课程表、成绩单、考试安排等，仅用于在 App 内展示。

3. 密码安全与处理机制
*   **内存运行**：您的教务系统密码仅在您进行登录、刷新数据等主动操作时，临时加载于手机内存中，用于向学校服务器发送请求。
*   **绝不上传**：我们承诺，**绝不**将您的账号和密码上传至除学校官方教务系统以外的任何第三方服务器。
*   **本地存储**：除用户明确选择“记住密码”等功能外，软件原则上不在本地文件或数据库中明文保存您的密码。如果保存，建议您保护好手机及设备安全。

4. 信息的存储
*   **本地缓存**：获取到的课表、成绩等数据会保存在您手机的本地存储空间（如 SharedPreferences 或 SQLite 数据库），以便您在离线状态下查看。
*   **数据清除**：您可以随时通过“注销/退出登录”功能清除本地存储的个人教务数据。卸载本软件也会同时删除所有本地缓存数据。

5. 权限调用说明
*   **网络权限**：用于连接学校教务系统服务器（获取数据）。
*   **存储权限**（可选）：仅当您使用“导出课表/校历”等功能需要保存文件时申请。

6. 第三方服务与统计
为持续改进软件体验，修复崩溃问题，本软件可能会集成匿名的第三方统计工具（如 Sentry, Firebase Crashlytics 等）。这些工具仅收集不包含个人身份信息的崩溃日志和功能使用频率数据。

7. 安全风险提示
*   由于本软件直接与学校教务系统交互，尽管我们采用主流安全技术，但无法控制学校服务器端的网络传输安全性（特别是若学校系统仅支持 HTTP 协议时）。
*   请勿在已 Root 或越狱的设备上使用本软件，这可能导致本地数据被恶意软件窃取。

8. 联系我们
如果您对本隐私政策或个人信息保护有任何疑问，请通过应用内的反馈渠道联系开发者。
''',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
