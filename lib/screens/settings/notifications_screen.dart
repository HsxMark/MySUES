import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
      ),
      body: ListView(
        children: const [
          ListTile(
            title: Text('课程提醒'),
            subtitle: Text('上课前15分钟提醒'),
            trailing: Switch(value: false, onChanged: null),
          ),
          ListTile(
            title: Text('考试提醒'),
            subtitle: Text('考试前1天提醒'),
            trailing: Switch(value: false, onChanged: null),
          ),
          ListTile(
            title: Text('成绩更新通知'),
            trailing: Switch(value: false, onChanged: null),
          ),
        ],
      ),
    );
  }
}
