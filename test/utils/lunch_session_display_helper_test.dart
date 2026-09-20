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

  test('editor target for merged pair keeps full range and both source ids', () {
    final morning = _course(id: 10, startNode: 3, step: 3);
    final afternoon = _course(id: 11, startNode: 6, step: 5);
    final display = LunchSessionDisplayHelper.prepareForDisplay(
      [morning, afternoon],
      splitLunch: false,
    ).single;
    final editor = LunchSessionDisplayHelper.courseForEditor(display, [
      morning,
      afternoon,
    ]);
    expect(editor.startNode, 3);
    expect(editor.step, 8);
    expect(editor.displaySourceIds, containsAll([10, 11]));
    expect(
      LunchSessionDisplayHelper.resolveSources(editor, [
        morning,
        afternoon,
      ]).length,
      2,
    );
  });

  test('editor target for split segment resolves to full stored course', () {
    final long = _course(id: 42, startNode: 3, step: 8);
    final display = LunchSessionDisplayHelper.prepareForDisplay(
      [long],
      splitLunch: true,
    ).last;
    final editor = LunchSessionDisplayHelper.courseForEditor(display, [long]);
    expect(editor.id, 42);
    expect(editor.startNode, 3);
    expect(editor.step, 8);
    // 单源时返回库中对象本身（不污染存储）；sourceIds 由调用方用 resolveSources 得到
    expect(
      LunchSessionDisplayHelper.resolveSources(display, [long]).single.id,
      42,
    );
  });
}
