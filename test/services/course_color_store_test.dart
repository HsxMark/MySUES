import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/services/course_color_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('starts empty', () async {
    expect(await CourseColorStore.loadRecentColors(), isEmpty);
  });

  test('keeps the newest color first and normalizes input', () async {
    await CourseColorStore.addRecentColor('#a8707a');
    final colors = await CourseColorStore.addRecentColor('7e93a8');

    expect(colors, ['#7E93A8', '#A8707A']);
    expect(await CourseColorStore.loadRecentColors(), ['#7E93A8', '#A8707A']);
  });

  test('moves a repeated color back to the front', () async {
    await CourseColorStore.addRecentColor('#A8707A');
    await CourseColorStore.addRecentColor('#7E93A8');
    final colors = await CourseColorStore.addRecentColor('#a8707a');

    expect(colors, ['#A8707A', '#7E93A8']);
  });

  test('caps the list at six colors', () async {
    const added = [
      '#111111',
      '#222222',
      '#333333',
      '#444444',
      '#555555',
      '#666666',
      '#777777',
    ];
    for (final hex in added) {
      await CourseColorStore.addRecentColor(hex);
    }

    final colors = await CourseColorStore.loadRecentColors();
    expect(colors, hasLength(CourseColorStore.maxRecentColors));
    expect(colors.first, '#777777');
    expect(colors, isNot(contains('#111111')));
  });

  test('ignores invalid colors without touching the list', () async {
    await CourseColorStore.addRecentColor('#A8707A');

    expect(await CourseColorStore.addRecentColor('nope'), ['#A8707A']);
    expect(await CourseColorStore.addRecentColor(null), ['#A8707A']);
  });

  test('survives malformed stored data', () async {
    SharedPreferences.setMockInitialValues({
      'recent_course_colors_v1': 'not json',
    });
    expect(await CourseColorStore.loadRecentColors(), isEmpty);

    SharedPreferences.setMockInitialValues({
      'recent_course_colors_v1': '{"colors": ["#A8707A"]}',
    });
    expect(await CourseColorStore.loadRecentColors(), isEmpty);

    SharedPreferences.setMockInitialValues({
      'recent_course_colors_v1': '["#zzzzzz", "#A8707A", "#a8707a", 7]',
    });
    expect(await CourseColorStore.loadRecentColors(), ['#A8707A']);
  });
}
