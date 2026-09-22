import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/models/course.dart';
import 'package:mysues/models/course_detail.dart';
import 'package:mysues/models/schedule_table.dart';
import 'package:mysues/services/schedule_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Course _course(String name, {int tableId = 0}) {
  return Course(
    courseName: name,
    day: 1,
    startNode: 1,
    step: 2,
    startWeek: 1,
    endWeek: 16,
    color: '#2196F3',
    tableId: tableId,
  );
}

SemesterCourseCatalog _catalog(String name, {int tableId = 0}) {
  return SemesterCourseCatalog(
    tableId: tableId,
    semesterName: name,
    totalCredits: 1,
    courses: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('creates a table when the semester was never imported', () async {
    final table = await ScheduleDataService.upsertScheduleTable(
      semesterName: '2025-2026-1',
      startDate: '2025-09-01',
    );

    expect(table.id, greaterThan(0));
    final tables = await ScheduleDataService.loadScheduleTables();
    expect(tables, hasLength(1));
    expect(tables.single.tableName, '2025-2026-1');
    expect(tables.single.startDate, '2025-09-01');
  });

  test('reuses the existing table and keeps its display settings', () async {
    final existing = ScheduleTable(
      tableName: '2025-2026-1',
      startDate: '2024-09-01',
      nodes: 12,
      background: 'custom-bg',
      showSat: false,
    );
    await ScheduleDataService.addScheduleTable(existing);

    final table = await ScheduleDataService.upsertScheduleTable(
      semesterName: '2025-2026-1',
      startDate: '2025-09-01',
    );

    expect(table.id, existing.id);
    expect(table.startDate, '2025-09-01');
    expect(table.nodes, 12);
    expect(table.background, 'custom-bg');
    expect(table.showSat, isFalse);
    expect(await ScheduleDataService.loadScheduleTables(), hasLength(1));
  });

  test('replaceCoursesForTable swaps only the target table', () async {
    final first = ScheduleTable(tableName: 'A', startDate: '2025-09-01');
    final second = ScheduleTable(tableName: 'B', startDate: '2025-09-01');
    await ScheduleDataService.addScheduleTable(first);
    await ScheduleDataService.addScheduleTable(second);

    await ScheduleDataService.replaceCoursesForTable(
      tableId: first.id,
      courses: [_course('老课')],
      catalog: _catalog('A'),
    );
    await ScheduleDataService.replaceCoursesForTable(
      tableId: second.id,
      courses: [_course('B 课')],
      catalog: _catalog('B'),
    );

    await ScheduleDataService.replaceCoursesForTable(
      tableId: first.id,
      courses: [_course('新课 1'), _course('新课 2'), _course('新课 3')],
      catalog: _catalog('A'),
    );

    final firstCourses = await ScheduleDataService.loadCourses(
      tableId: first.id,
    );
    final secondCourses = await ScheduleDataService.loadCourses(
      tableId: second.id,
    );

    expect(firstCourses.map((c) => c.courseName), [
      '新课 1',
      '新课 2',
      '新课 3',
    ]);
    expect(firstCourses.every((c) => c.tableId == first.id), isTrue);
    expect(secondCourses.map((c) => c.courseName), ['B 课']);

    final ids = [
      ...firstCourses.map((c) => c.id),
      ...secondCourses.map((c) => c.id),
    ];
    expect(ids.toSet(), hasLength(ids.length));

    final catalogs = await ScheduleDataService.loadCourseCatalogs();
    expect(catalogs, hasLength(2));
    expect(
      catalogs.where((catalog) => catalog.tableId == first.id),
      hasLength(1),
    );
    expect(await ScheduleDataService.getCurrentTableId(), first.id);
  });
}
