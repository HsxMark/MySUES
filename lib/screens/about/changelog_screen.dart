import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('版本更新'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildVersionCard(
            context,
            version: '0.3.1-beta.1',
            date: '2026-02-27',
            changes: [
              '🌟 在从教务处同步数据前添加免责声明弹窗，提醒用户核对导入数据',
              '🐛 修复课表最大周数默认值，从 20 调整为 30',
              '🛠 改进课表切换底部弹窗 UI',
            ],
            isLatest: true,
          ),
          _buildVersionCard(
            context,
            version: '0.3.0-beta.1',
            date: '2026-02-26',
            changes: [
              '🌟 在首次启动免责声明弹窗中添加 QQ 群反馈入口',
              '🛠 升级项目依赖版本',
              '🛠 为课表切换页面添加液态玻璃效果'
            ],
          ),
          _buildVersionCard(
            context,
            version: '0.2.0-beta.1',
            date: '2026-02-19',
            changes: [
              '🌟 支持课程提醒通知，上课前 15 分钟推送提醒，显示课程名称和教室信息',
              '🌟 支持考试提醒通知，可自定义提前天数（1–7 天）和提醒时间',
              '🛠 配置 Android 通知权限及开机自启接收器，确保定时通知正常调度',
              '🛠 移除关于页面中的功能介绍入口',
            ],
          ),
          _buildVersionCard(
            context,
            version: '0.1.0-beta.1',
            date: '2026-02-10',
            changes: [
              '🔥 实现课程表周视图，支持单周/双周课程显示',
              '🔥 实现成绩单查询，支持绩点计算和成绩详情弹窗',
              '🔥 支持通过 WebVPN 从教务系统获取考试信息',
              '🔥 引入 Liquid Glass 毛玻璃 UI 效果，覆盖底部导航栏、弹窗、菜单和个人主页',
              '🌟 支持通过 WebView 登录 WebVPN，安全获取教务数据',
              '🌟 支持从 WebVPN 导入课表时自动获取和选择学期',
              '🌟 支持 PDF 格式课表导入，离线也能查看',
              '🌟 添加个人主页，支持学生信息展示、资料编辑和自定义壁纸背景',
              '🌟 支持深色模式，全应用适配',
              '🌟 支持自定义作息时间表，可配置每天最多 15 个节次的时间段',
              '🌟 支持在课表视图中切换周末显示',
              '🌟 添加启动页和首次启动免责声明弹窗',
              '🌟 添加关于页面，包含更新日志、功能介绍、开源许可证、隐私政策和赞助信息',
              '🌟 添加用户协议和隐私政策页面，支持 Markdown 渲染',
              '🌟 添加课表、成绩、考试数据页面的自动刷新逻辑',
              '🐛 修复设置个人背景图片时的屏幕显示问题',
              '🐛 修复数据更新后成绩页面未正确刷新的问题',
              '🐛 修复个人主页学号显示错误',
              '🐛 修复 iPhone 用户在 Safari 中的 WebVPN 数据获取错误',
              '🐛 修复非教学周期间课表显示异常',
              '🐛 修复课表周末逻辑计算错误',
              '🐛 修复多个成绩计算和存储相关的问题',
              '🐛 修复获取考试数据后的显示错误',
              '🐛 修复 Cookie 处理问题导致的重复登录提示',
              '🐛 修复课表格子颜色渲染错误',
              '🐛 修复个人主页背景图片显示异常',
              '🛠 删除更新日志中的自动更新功能，修复相关问题',
              '🛠 重写课表数据获取逻辑，提升稳定性',
              '🛠 添加入口限制，防止用户在同意条款前访问应用',
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  '本应用不支持自动检查更新',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('https://syntrion.dev/mysues')),
                  child: Text(
                    '前往 syntrion.dev/mysues 下载最新版本',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard(BuildContext context, {
    required String version,
    required String date,
    required List<String> changes,
    bool isLatest = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'v$version',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (isLatest)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '最新',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                const Spacer(),
                Text(
                  date,
                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),
            ...changes.map((change) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(change)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
