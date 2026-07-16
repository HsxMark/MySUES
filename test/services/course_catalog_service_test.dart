import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/models/course_detail.dart';
import 'package:mysues/models/schedule_table.dart';
import 'package:mysues/services/schedule_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'course catalogs round-trip by table and are deleted with the table',
    () async {
      final table = ScheduleTable(
        tableName: '2026-2027学年第1学期',
        startDate: '2026-09-14',
      );
      await ScheduleDataService.addScheduleTable(table);

      final catalog = SemesterCourseCatalog(
        tableId: table.id,
        semesterName: table.tableName,
        totalCredits: 6.25,
        courses: const [
          CourseDetail(
            sourceKey: 'lesson:1',
            lessonId: 1,
            courseName: '专业综合设计',
            courseCode: '020612',
            courseType: '集中实践教学环节',
            examMode: '考查',
            openDepartment: '电子电气工程学院',
            teachingFormat: '理论课、实验课',
            credits: 2,
            periodInfo: CoursePeriodInfo(total: 60, weeks: 2, experiment: 60),
          ),
        ],
      );
      await ScheduleDataService.saveCourseCatalog(catalog);

      final loaded = await ScheduleDataService.loadCourseCatalog(
        tableId: table.id,
      );
      expect(loaded, isNotNull);
      expect(loaded!.totalCredits, 6.25);
      expect(loaded.courses.single.courseCode, '020612');

      await ScheduleDataService.deleteScheduleTable(table.id);
      expect(
        await ScheduleDataService.loadCourseCatalog(tableId: table.id),
        isNull,
      );
    },
  );
}
