import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/app_localizations.dart';
import 'package:mysues/models/course.dart';
import 'package:mysues/screens/add_course_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Host extends StatefulWidget {
  const _Host({this.course});

  final Course? course;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  Course? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final value = await Navigator.of(context).push<Course>(
              MaterialPageRoute(
                builder: (_) => AddCourseScreen(course: widget.course),
              ),
            );
            if (!mounted) return;
            setState(() => result = value);
          },
          child: const Text('open-editor'),
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

Course _course({required String color}) {
  return Course(
    id: 7,
    courseName: '高等数学',
    day: 3,
    room: 'A101',
    teacher: '张老师',
    startNode: 3,
    step: 2,
    startWeek: 1,
    endWeek: 16,
    color: color,
    tableId: 1,
  );
}

String _selectedHex(WidgetTester tester) {
  return tester
      .widget<Text>(find.byKey(const ValueKey('course-color-selected-hex')))
      .data!;
}

Future<_HostState> _openEditor(WidgetTester tester, {Course? course}) async {
  // The editor is long; give it a tall viewport so the save button stays
  // reachable without fighting the scroll view.
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_wrap(_Host(course: course)));
  await tester.tap(find.text('open-editor'));
  await tester.pumpAndSettle();
  // The host page is offstage while the editor route is on top.
  return tester.state<_HostState>(find.byType(_Host, skipOffstage: false));
}

Future<void> _save(WidgetTester tester) async {
  final saveButton = find.widgetWithText(FilledButton, '保存');
  await tester.ensureVisible(saveButton);
  await tester.pumpAndSettle();
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('a new course starts on the classic default color', (
    tester,
  ) async {
    final host = await _openEditor(tester);

    expect(_selectedHex(tester), '#2196F3');

    await tester.enterText(find.byType(TextFormField).first, '线性代数');
    await _save(tester);

    expect(host.result, isNotNull);
    expect(host.result!.courseName, '线性代数');
    expect(host.result!.color, '#2196F3');
  });

  testWidgets('editing a Morandi colored course keeps that color', (
    tester,
  ) async {
    final host = await _openEditor(tester, course: _course(color: '#A8707A'));

    expect(_selectedHex(tester), '#A8707A');
    expect(find.byIcon(Icons.check), findsOneWidget);

    await _save(tester);

    expect(host.result, isNotNull);
    expect(host.result!.color, '#A8707A');
  });

  testWidgets('editing a course with a color outside the presets keeps it', (
    tester,
  ) async {
    final host = await _openEditor(tester, course: _course(color: '#123456'));

    expect(_selectedHex(tester), '#123456');
    expect(find.byIcon(Icons.check), findsNothing);

    await _save(tester);

    expect(host.result, isNotNull);
    expect(host.result!.color, '#123456');
  });

  testWidgets('picking a preset swatch is saved with the course', (
    tester,
  ) async {
    final host = await _openEditor(tester);

    final swatch = find.byKey(const ValueKey('course-color-#6F8F86'));
    await tester.ensureVisible(swatch);
    await tester.pumpAndSettle();
    await tester.tap(swatch);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '大学英语');
    await _save(tester);

    expect(host.result!.color, '#6F8F86');
  });
}
