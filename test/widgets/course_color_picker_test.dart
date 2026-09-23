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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows both preset groups and marks the selected color', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const _PickerHarness()));
    await tester.pumpAndSettle();

    expect(find.text('经典'), findsOneWidget);
    expect(find.text('莫兰迪'), findsOneWidget);
    expect(find.text('最近使用'), findsNothing);

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

    expect(_selectedHex(tester), '#2196F3');
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('selecting a Morandi color updates the selection', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const _PickerHarness()));
    await tester.pumpAndSettle();

    final swatch = find.byKey(const ValueKey('course-color-#A8707A'));
    await tester.ensureVisible(swatch);
    await tester.pumpAndSettle();
    await tester.tap(swatch);
    await tester.pumpAndSettle();

    expect(_selectedHex(tester), '#A8707A');
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('highlights a Morandi color that is already selected', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const _PickerHarness(initialHex: '#6F8F86')));
    await tester.pumpAndSettle();

    expect(_selectedHex(tester), '#6F8F86');
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('custom sheet normalizes the hex input and remembers it', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const _PickerHarness()));
    await tester.pumpAndSettle();

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
    expect(await CourseColorStore.loadRecentColors(), ['#12AB34']);
    expect(find.text('最近使用'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('course-color-custom')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recent-color-#12AB34')), findsOneWidget);
  });

  testWidgets('invalid hex input blocks confirmation', (tester) async {
    await tester.pumpWidget(_wrap(const _PickerHarness()));
    await tester.pumpAndSettle();

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
