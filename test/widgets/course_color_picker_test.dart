import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/services/course_color_store.dart';
import 'package:mysues/theme/course_palette.dart';
import 'package:mysues/widgets/course_color_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kAddButton = 'course-color-save';
const String kDeleteButton = 'course-color-delete';
const String kHexField = 'course-color-hex-field';
const String kConfirmButton = 'course-color-confirm';

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

String _hexFieldText(WidgetTester tester) {
  return tester
      .widget<TextField>(find.byKey(const ValueKey(kHexField)))
      .controller!
      .text;
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

Future<void> _tapAdd(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey(kAddButton)));
  await tester.pumpAndSettle();
}

Future<void> _openSavedEditor(WidgetTester tester, String hex) async {
  await tester.longPress(find.byKey(ValueKey('saved-color-$hex')));
  await tester.pumpAndSettle();
}

Future<void> _confirmHex(WidgetTester tester, String hex) async {
  await tester.enterText(find.byKey(const ValueKey(kHexField)), hex);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey(kConfirmButton)));
  await tester.pumpAndSettle();
}

/// The editor sheet has its own buttons, so dialog buttons are scoped to the
/// confirmation dialog.
Finder _dialogButton(String label) {
  return find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(TextButton, label),
  );
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
    expect(find.byKey(const ValueKey(kAddButton)), findsOneWidget);
    // The custom palette entry was merged into the add button.
    expect(find.byKey(const ValueKey('course-color-custom')), findsNothing);

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

  testWidgets('the add button opens the picker and only saves on confirm', (
    tester,
  ) async {
    await _pumpPicker(tester);
    await _expand(tester);

    await _tapAdd(tester);
    expect(find.text('选择颜色'), findsOneWidget);
    // Adding a new color has nothing to delete yet.
    expect(find.byKey(const ValueKey(kDeleteButton)), findsNothing);
    expect(await CourseColorStore.loadSavedColors(), isEmpty);

    await _confirmHex(tester, '#12ab34');

    expect(find.byKey(const ValueKey('saved-color-#12AB34')), findsOneWidget);
    expect(await CourseColorStore.loadSavedColors(), ['#12AB34']);
    expect(find.text('已保存到「我的颜色」'), findsOneWidget);
    // Saving a color must not change the course color.
    expect(_selectedHex(tester), '#2196F3');
  });

  testWidgets('dismissing the picker saves nothing', (tester) async {
    await _pumpPicker(tester);
    await _expand(tester);
    await _tapAdd(tester);

    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();

    expect(await CourseColorStore.loadSavedColors(), isEmpty);
    expect(find.byKey(const ValueKey(kAddButton)), findsOneWidget);
  });

  testWidgets('the add button rejects a color that is already saved', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'saved_course_colors_v1': '["#A8707A"]',
    });
    await _pumpPicker(tester);
    await _expand(tester);

    await _tapAdd(tester);
    await _confirmHex(tester, '#a8707a');

    expect(find.text('该颜色已在「我的颜色」中'), findsOneWidget);
    expect(await CourseColorStore.loadSavedColors(), ['#A8707A']);
  });

  testWidgets('the add button disappears when twelve colors are saved', (
    tester,
  ) async {
    for (var i = 0; i < CourseColorStore.maxSavedColors; i++) {
      await CourseColorStore.addSavedColor(
        '#${(0x101010 + i * 0x0F0F0F).toRadixString(16).padLeft(6, '0')}',
      );
    }
    await _pumpPicker(tester);
    await _expand(tester);

    expect(
      await CourseColorStore.loadSavedColors(),
      hasLength(CourseColorStore.maxSavedColors),
    );
    expect(find.byKey(const ValueKey(kAddButton)), findsNothing);
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

  testWidgets('long pressing a saved color opens its editor', (tester) async {
    SharedPreferences.setMockInitialValues({
      'saved_course_colors_v1': '["#A8707A"]',
    });
    await _pumpPicker(tester);
    await _expand(tester);

    await _openSavedEditor(tester, '#A8707A');

    expect(find.text('编辑颜色'), findsOneWidget);
    expect(find.text('选择颜色'), findsNothing);
    expect(_hexFieldText(tester), '#A8707A');
    expect(find.byKey(const ValueKey(kDeleteButton)), findsOneWidget);
  });

  testWidgets('the editor keeps delete away from cancel and confirm', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'saved_course_colors_v1': '["#A8707A"]',
    });
    await _pumpPicker(tester);
    await _expand(tester);
    await _openSavedEditor(tester, '#A8707A');

    final deleteButton = find.byKey(const ValueKey(kDeleteButton));
    final cancelButton = find.widgetWithText(TextButton, '取消');
    final confirmButton = find.byKey(const ValueKey(kConfirmButton));

    expect(tester.widget(deleteButton), isA<TextButton>());
    expect(tester.widget(confirmButton), isA<FilledButton>());
    expect(
      tester.getCenter(deleteButton).dx,
      lessThan(tester.getCenter(cancelButton).dx),
    );
    expect(
      tester.getCenter(cancelButton).dx,
      lessThan(tester.getCenter(confirmButton).dx),
    );
  });

  testWidgets('deleting inside the editor asks for confirmation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'saved_course_colors_v1': '["#A8707A"]',
    });
    await _pumpPicker(tester);
    await _expand(tester);
    await _openSavedEditor(tester, '#A8707A');

    await tester.tap(find.byKey(const ValueKey(kDeleteButton)));
    await tester.pumpAndSettle();
    expect(find.text('删除保存的颜色'), findsOneWidget);

    await tester.tap(_dialogButton('删除'));
    await tester.pumpAndSettle();

    expect(find.text('编辑颜色'), findsNothing);
    expect(find.byKey(const ValueKey('saved-color-#A8707A')), findsNothing);
    expect(await CourseColorStore.loadSavedColors(), isEmpty);
  });

  testWidgets('cancelling the delete confirmation keeps the editor open', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'saved_course_colors_v1': '["#A8707A"]',
    });
    await _pumpPicker(tester);
    await _expand(tester);
    await _openSavedEditor(tester, '#A8707A');

    await tester.tap(find.byKey(const ValueKey(kDeleteButton)));
    await tester.pumpAndSettle();
    await tester.tap(_dialogButton('取消'));
    await tester.pumpAndSettle();

    expect(find.text('删除保存的颜色'), findsNothing);
    expect(find.text('编辑颜色'), findsOneWidget);
    expect(await CourseColorStore.loadSavedColors(), ['#A8707A']);
  });

  testWidgets('editing a saved color replaces it in place', (tester) async {
    SharedPreferences.setMockInitialValues({
      'saved_course_colors_v1': '["#7E93A8", "#A8707A"]',
    });
    await _pumpPicker(tester);
    await _expand(tester);
    await _openSavedEditor(tester, '#A8707A');

    await _confirmHex(tester, '#123456');

    expect(await CourseColorStore.loadSavedColors(), ['#7E93A8', '#123456']);
    expect(find.text('颜色已更新'), findsOneWidget);
    // Editing a saved color never touches the course color.
    expect(_selectedHex(tester), '#2196F3');
  });

  testWidgets('editing rejects a color that is already saved', (tester) async {
    SharedPreferences.setMockInitialValues({
      'saved_course_colors_v1': '["#7E93A8", "#A8707A"]',
    });
    await _pumpPicker(tester);
    await _expand(tester);
    await _openSavedEditor(tester, '#A8707A');

    await _confirmHex(tester, '#7e93a8');

    expect(find.text('该颜色已在「我的颜色」中'), findsOneWidget);
    expect(await CourseColorStore.loadSavedColors(), ['#7E93A8', '#A8707A']);
  });

  testWidgets('the picker sheet renders a single drag handle', (tester) async {
    await _pumpPicker(tester);
    await _expand(tester);
    await _tapAdd(tester);

    // The theme sets showDragHandle: true; the sheet opts out and draws its own.
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle,
      isFalse,
    );
  });

  testWidgets('invalid hex input blocks confirmation', (tester) async {
    await _pumpPicker(tester);
    await _expand(tester);
    await _tapAdd(tester);

    final hexField = find.byKey(const ValueKey(kHexField));
    final confirm = find.byKey(const ValueKey(kConfirmButton));

    await tester.enterText(hexField, '#12345');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(hexField, '#1234567');
    await tester.pumpAndSettle();
    expect(find.text('请输入 6 位十六进制颜色，例如 #A8707A'), findsOneWidget);
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
  });
}
