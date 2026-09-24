import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/services/course_color_store.dart';
import 'package:mysues/theme/course_palette.dart';
import 'package:mysues/widgets/course_color_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PickerHarness extends StatefulWidget {
  const _PickerHarness({this.initialHex = '#2196F3'});

  final String initialHex;

  @override
  State<_PickerHarness> createState() => _PickerHarnessState();
}

class _PickerHarnessState extends State<_PickerHarness> {
  late String selectedHex = widget.initialHex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: CourseColorPicker(
          selectedHex: selectedHex,
          onChanged: (hex) => setState(() => selectedHex = hex),
        ),
      ),
    );
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

String _selectedHex(WidgetTester tester) {
  return tester
      .widget<Text>(find.byKey(const ValueKey('course-color-selected-hex')))
      .data!;
}

Future<void> _pumpPicker(
  WidgetTester tester, {
  String initialHex = '#2196F3',
}) async {
  // Keep the whole expanded panel on screen so swatches stay tappable.
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_wrap(_PickerHarness(initialHex: initialHex)));
  await tester.pumpAndSettle();
}

Future<void> _expand(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('course-color-toggle')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('starts collapsed and shows the selected color', (tester) async {
    await _pumpPicker(tester);

    expect(find.byKey(const ValueKey('course-color-toggle')), findsOneWidget);
    expect(_selectedHex(tester), '#2196F3');
    expect(find.text('经典'), findsNothing);
    expect(find.text('莫兰迪'), findsNothing);
    expect(find.text('我的颜色'), findsNothing);
  });

  testWidgets('expanding shows the preset groups and my colors', (
    tester,
  ) async {
    await _pumpPicker(tester);
    await _expand(tester);

    expect(find.text('经典'), findsOneWidget);
    expect(find.text('莫兰迪'), findsOneWidget);
    expect(find.text('我的颜色'), findsOneWidget);
    expect(find.byKey(const ValueKey('course-color-save')), findsOneWidget);

    for (final hex in [
      ...CoursePalette.classicHexes,
      ...CoursePalette.morandiHexes,
    ]) {
      expect(
        find.byKey(ValueKey('course-color-$hex')),
        findsOneWidget,
        reason: hex,
      );
    }
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('collapsing hides the panel again', (tester) async {
    await _pumpPicker(tester);
    await _expand(tester);
    await _expand(tester);

    expect(find.text('经典'), findsNothing);
    expect(find.text('我的颜色'), findsNothing);
  });

  testWidgets('selecting a Morandi color updates the selection', (
    tester,
  ) async {
    await _pumpPicker(tester);
    await _expand(tester);

    await tester.tap(find.byKey(const ValueKey('course-color-#A8707A')));
    await tester.pumpAndSettle();

    expect(_selectedHex(tester), '#A8707A');
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('highlights a Morandi color that is already selected', (
    tester,
  ) async {
    await _pumpPicker(tester, initialHex: '#6F8F86');
    await _expand(tester);

    expect(_selectedHex(tester), '#6F8F86');
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('saving the current color adds it to My Colors', (tester) async {
    await _pumpPicker(tester);
    await _expand(tester);

    await tester.tap(find.byKey(const ValueKey('course-color-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('saved-color-#2196F3')), findsOneWidget);
    expect(find.text('已保存到「我的颜色」'), findsOneWidget);
    expect(await CourseColorStore.loadSavedColors(), ['#2196F3']);
  });

  testWidgets('tapping a saved color applies it', (tester) async {
    SharedPreferences.setMockInitialValues({
      'saved_course_colors_v1': '["#A8707A"]',
    });
    await _pumpPicker(tester);
    await _expand(tester);

    await tester.tap(find.byKey(const ValueKey('saved-color-#A8707A')));
    await tester.pumpAndSettle();

    expect(_selectedHex(tester), '#A8707A');
  });

  testWidgets('saving the same color twice is rejected', (tester) async {
    await _pumpPicker(tester);
    await _expand(tester);

    final saveButton = find.byKey(const ValueKey('course-color-save'));
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('该颜色已在「我的颜色」中'), findsOneWidget);
    expect(await CourseColorStore.loadSavedColors(), ['#2196F3']);
  });

  testWidgets('saving stops at the twelve color limit', (tester) async {
    for (var i = 0; i < CourseColorStore.maxSavedColors; i++) {
      await CourseColorStore.addSavedColor(
        '#${(0x101010 + i * 0x0F0F0F).toRadixString(16).padLeft(6, '0')}',
      );
    }
    await _pumpPicker(tester);
    await _expand(tester);

    await tester.tap(find.byKey(const ValueKey('course-color-save')));
    await tester.pumpAndSettle();

    expect(find.text('最多保存 12 个颜色，请先长按删除'), findsOneWidget);
    expect(await CourseColorStore.loadSavedColors(), hasLength(12));
    expect(find.byKey(const ValueKey('saved-color-#2196F3')), findsNothing);
  });

  testWidgets('long pressing a saved color deletes it after confirmation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'saved_course_colors_v1': '["#A8707A"]',
    });
    await _pumpPicker(tester);
    await _expand(tester);

    await tester.longPress(find.byKey(const ValueKey('saved-color-#A8707A')));
    await tester.pumpAndSettle();
    expect(find.text('删除保存的颜色'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('saved-color-#A8707A')), findsNothing);
    expect(await CourseColorStore.loadSavedColors(), isEmpty);
  });

  testWidgets('cancelling the delete keeps the saved color', (tester) async {
    SharedPreferences.setMockInitialValues({
      'saved_course_colors_v1': '["#A8707A"]',
    });
    await _pumpPicker(tester);
    await _expand(tester);

    await tester.longPress(find.byKey(const ValueKey('saved-color-#A8707A')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('saved-color-#A8707A')), findsOneWidget);
    expect(await CourseColorStore.loadSavedColors(), ['#A8707A']);
  });

  testWidgets('custom sheet normalizes the hex input and applies it', (
    tester,
  ) async {
    await _pumpPicker(tester);
    await _expand(tester);

    await tester.tap(find.byKey(const ValueKey('course-color-custom')));
    await tester.pumpAndSettle();
    expect(find.text('选择颜色'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('course-color-hex-field')),
      '#12ab34',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('course-color-confirm')));
    await tester.pumpAndSettle();

    expect(_selectedHex(tester), '#12AB34');
    expect(await CourseColorStore.loadSavedColors(), isEmpty);
  });

  testWidgets('invalid hex input blocks confirmation', (tester) async {
    await _pumpPicker(tester);
    await _expand(tester);

    await tester.tap(find.byKey(const ValueKey('course-color-custom')));
    await tester.pumpAndSettle();

    final hexField = find.byKey(const ValueKey('course-color-hex-field'));
    final confirm = find.byKey(const ValueKey('course-color-confirm'));

    await tester.enterText(hexField, '#12345');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(hexField, '#1234567');
    await tester.pumpAndSettle();
    expect(find.text('请输入 6 位十六进制颜色，例如 #A8707A'), findsOneWidget);
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
  });
}
