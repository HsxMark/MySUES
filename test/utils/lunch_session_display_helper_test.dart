import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/models/course.dart';
import 'package:mysues/utils/lunch_session_display_helper.dart';

Course _course({
  required int id,
  required int startNode,
  required int step,
  String name = '专业综合设计',
  String room = '交7409',
}) {
  return Course(
    id: id,
    courseName: name,
    day: 2,
    room: room,
    teacher: '老师',
    startNode: startNode,
    step: step,
    startWeek: 1,
    endWeek: 16,
    color: '#2196F3',
    tableId: 1,
  );
}

void main() {
  test('toggle off merges lunch halves and carries both source ids', () {
    final morning = _course(id: 10, startNode: 3, step: 3);
    final afternoon = _course(id: 11, startNode: 6, step: 5);
    // 乱序：下午在前，仍应合并
    final display = LunchSessionDisplayHelper.prepareForDisplay(
      [afternoon, morning],
      splitLunch: false,
    );
    expect(display.length, 1);
    expect(display.first.startNode, 3);
    expect(display.first.step, 8);
    expect(display.first.displaySourceIds, containsAll([10, 11]));

    final sources = LunchSessionDisplayHelper.resolveSources(
      display.first,
      [morning, afternoon],
    );
    expect(sources.length, 2);
    expect(sources.map((c) => c.id), containsAll([10, 11]));
  });

  test('toggle on splits cross-noon course but keeps single source id', () {
    final long = _course(id: 42, startNode: 3, step: 8);
    final display = LunchSessionDisplayHelper.prepareForDisplay(
      [long],
      splitLunch: true,
    );
    expect(display.length, 2);
    expect(display[0].startNode, 3);
    expect(display[0].step, 3);
    expect(display[1].startNode, 6);
    expect(display[1].step, 5);
    for (final d in display) {
      expect(d.displaySourceIds, [42]);
    }
    final sources = LunchSessionDisplayHelper.resolveSources(display[1], [long]);
    expect(sources.single.id, 42);
    expect(sources.single.step, 8);
  });
}
