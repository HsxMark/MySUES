import 'package:flutter/material.dart';
import 'schedule_screen.dart';
import 'daily_schedule_screen.dart';

/// 课表视图容器，管理周视图和日视图之间的切换
class ScheduleViewContainer extends StatefulWidget {
  const ScheduleViewContainer({super.key});

  /// 全局 key，用于外部触发视图切换
  static final GlobalKey<ScheduleViewContainerState> containerKey =
      GlobalKey<ScheduleViewContainerState>();

  @override
  State<ScheduleViewContainer> createState() => ScheduleViewContainerState();
}

class ScheduleViewContainerState extends State<ScheduleViewContainer> {
  bool _isDailyView = false;

  void toggleView() {
    setState(() {
      _isDailyView = !_isDailyView;
    });
  }

  void setDailyView(bool daily) {
    if (_isDailyView != daily) {
      setState(() {
        _isDailyView = daily;
      });
    }
  }

  bool get isDailyView => _isDailyView;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _isDailyView
          ? DailyScheduleScreen(
              key: const ValueKey('daily'),
              onSwitchToWeek: () => setDailyView(false),
            )
          : ScheduleScreen(
              key: const ValueKey('week'),
              onSwitchToDaily: () => setDailyView(true),
            ),
    );
  }
}
