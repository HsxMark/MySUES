import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'schedule_screen.dart';
import 'daily_schedule_screen.dart';
import '../widgets/draggable_floating_button.dart';

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
  bool _isLoading = true;

  // FAB position (persisted)
  double _fabDx = -1;
  double _fabDy = -1;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDailyView = prefs.getBool('is_daily_view') ?? false;
      _fabDx = prefs.getDouble('schedule_fab_dx') ?? -1;
      _fabDy = prefs.getDouble('schedule_fab_dy') ?? -1;
      _isLoading = false;
    });
  }

  Future<void> _saveViewPreference(bool isDaily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_daily_view', isDaily);
  }

  Future<void> _saveFabPosition(double dx, double dy) async {
    _fabDx = dx;
    _fabDy = dy;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('schedule_fab_dx', dx);
    await prefs.setDouble('schedule_fab_dy', dy);
  }

  void toggleView() {
    setState(() {
      _isDailyView = !_isDailyView;
    });
    _saveViewPreference(_isDailyView);
  }

  void setDailyView(bool daily) {
    if (_isDailyView != daily) {
      setState(() {
        _isDailyView = daily;
      });
      _saveViewPreference(daily);
    }
  }

  bool get isDailyView => _isDailyView;

  // --- FAB logic ---

  bool get _shouldShowFab {
    if (_isDailyView) {
      return DailyScheduleScreen.currentState?.showFloatingButton ?? false;
    } else {
      return ScheduleScreen.currentState?.showFloatingButton ?? false;
    }
  }

  String get _fabLabel {
    if (_isDailyView) {
      final state = DailyScheduleScreen.currentState;
      if (state == null) return '';
      final d = state.selectedDate;
      return '${d.month}/${d.day}';
    } else {
      final state = ScheduleScreen.currentState;
      if (state == null) return '';
      return '${state.currentWeek}';
    }
  }

  bool get _isAtHome {
    if (_isDailyView) {
      return DailyScheduleScreen.currentState?.isViewingToday ?? true;
    } else {
      return ScheduleScreen.currentState?.isOnActualCurrentWeek ?? true;
    }
  }

  void _onFabTap() {
    if (_isDailyView) {
      final state = DailyScheduleScreen.currentState;
      if (state == null) return;
      if (state.isViewingToday) {
        _showDateJumpDialog(state);
      } else {
        state.jumpToToday();
      }
    } else {
      final state = ScheduleScreen.currentState;
      if (state == null) return;
      if (state.isOnActualCurrentWeek) {
        _showWeekJumpDialog(state);
      } else {
        state.jumpToActualCurrentWeek();
      }
    }
  }

  void _showWeekJumpDialog(ScheduleScreenState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('跳转到周次'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '周次 (1-${state.maxWeek})',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              final week = int.tryParse(value);
              if (week != null && week >= 1 && week <= state.maxWeek) {
                Navigator.pop(ctx);
                state.jumpToWeek(week);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final week = int.tryParse(controller.text);
                if (week != null && week >= 1 && week <= state.maxWeek) {
                  Navigator.pop(ctx);
                  state.jumpToWeek(week);
                }
              },
              child: const Text('跳转'),
            ),
          ],
        );
      },
    );
  }

  void _showDateJumpDialog(DailyScheduleScreenState state) {
    showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: state.semesterStart,
      lastDate: state.semesterEnd,
    ).then((date) {
      if (date != null) {
        state.jumpToDate(date);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final showFab = _shouldShowFab;

    return Stack(
      children: [
        AnimatedSwitcher(
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
        ),
        if (showFab)
          DraggableFloatingButton(
            label: _fabLabel,
            isAtHome: _isAtHome,
            initialDx: _fabDx,
            initialDy: _fabDy,
            onTap: _onFabTap,
            onPositionChanged: _saveFabPosition,
          ),
      ],
    );
  }
}
