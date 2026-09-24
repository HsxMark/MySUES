import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/services/course_color_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('starts empty', () async {
    expect(await CourseColorStore.loadSavedColors(), isEmpty);
  });

  test('keeps the newest color first and normalizes input', () async {
    await CourseColorStore.addSavedColor('#a8707a');
    final colors = await CourseColorStore.addSavedColor('7e93a8');

    expect(colors, ['#7E93A8', '#A8707A']);
    expect(await CourseColorStore.loadSavedColors(), ['#7E93A8', '#A8707A']);
  });

  test('ignores a color that is already saved', () async {
    await CourseColorStore.addSavedColor('#A8707A');
    final colors = await CourseColorStore.addSavedColor('#a8707a');

    expect(colors, ['#A8707A']);
  });

  test('caps the list at twelve colors', () async {
    const added = [
      '#101010',
      '#202020',
      '#303030',
      '#404040',
      '#505050',
      '#606060',
      '#707070',
      '#808080',
      '#909090',
      '#A0A0A0',
      '#B0B0B0',
      '#C0C0C0',
      '#D0D0D0',
    ];
    for (final hex in added) {
      await CourseColorStore.addSavedColor(hex);
    }

    final colors = await CourseColorStore.loadSavedColors();
    expect(colors, hasLength(CourseColorStore.maxSavedColors));
    // The list was already full, so the thirteenth color is rejected.
    expect(colors.first, '#C0C0C0');
    expect(colors.last, '#101010');
    expect(colors, isNot(contains('#D0D0D0')));
  });

  test('removes a saved color', () async {
    await CourseColorStore.addSavedColor('#A8707A');
    await CourseColorStore.addSavedColor('#7E93A8');

    final colors = await CourseColorStore.removeSavedColor('#a8707a');

    expect(colors, ['#7E93A8']);
    expect(await CourseColorStore.loadSavedColors(), ['#7E93A8']);
  });

  test('removing an unknown or invalid color keeps the list', () async {
    await CourseColorStore.addSavedColor('#A8707A');

    expect(await CourseColorStore.removeSavedColor('#123456'), ['#A8707A']);
    expect(await CourseColorStore.removeSavedColor('nope'), ['#A8707A']);
    expect(await CourseColorStore.removeSavedColor(null), ['#A8707A']);
  });

  test('ignores invalid colors without touching the list', () async {
    await CourseColorStore.addSavedColor('#A8707A');

    expect(await CourseColorStore.addSavedColor('nope'), ['#A8707A']);
    expect(await CourseColorStore.addSavedColor(null), ['#A8707A']);
  });

  test('clears every saved color', () async {
    await CourseColorStore.addSavedColor('#A8707A');
    await CourseColorStore.clearSavedColors();

    expect(await CourseColorStore.loadSavedColors(), isEmpty);
  });

  test('survives malformed stored data', () async {
    SharedPreferences.setMockInitialValues({
      'saved_course_colors_v1': 'not json',
    });
    expect(await CourseColorStore.loadSavedColors(), isEmpty);

    SharedPreferences.setMockInitialValues({
      'saved_course_colors_v1': '{"colors": ["#A8707A"]}',
    });
    expect(await CourseColorStore.loadSavedColors(), isEmpty);

    SharedPreferences.setMockInitialValues({
      'saved_course_colors_v1': '["#zzzzzz", "#A8707A", "#a8707a", 7]',
    });
    expect(await CourseColorStore.loadSavedColors(), ['#A8707A']);
  });

  test('migrates the colors recorded by the previous recent list', () async {
    SharedPreferences.setMockInitialValues({
      'recent_course_colors_v1': '["#A8707A", "7e93a8", "#zzzzzz"]',
    });

    expect(await CourseColorStore.loadSavedColors(), ['#A8707A', '#7E93A8']);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('recent_course_colors_v1'), isNull);
    expect(jsonDecode(prefs.getString('saved_course_colors_v1')!) as List, [
      '#A8707A',
      '#7E93A8',
    ]);
  });

  test('does not migrate legacy colors twice', () async {
    SharedPreferences.setMockInitialValues({
      'recent_course_colors_v1': '["#A8707A"]',
    });
    expect(await CourseColorStore.loadSavedColors(), ['#A8707A']);

    await CourseColorStore.removeSavedColor('#A8707A');

    expect(await CourseColorStore.loadSavedColors(), isEmpty);
  });
}
