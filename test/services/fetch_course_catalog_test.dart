import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/services/webvpn/fetch_course_service.dart';

void main() {
  test(
    'course catalog merges rich records and includes courses without activities',
    () {
      final json = <String, dynamic>{
        'studentTableVms': [
          {
            'credits': 2.25,
            'activities': [
              {
                'courseName': '专业综合设计',
                'weekday': 1,
                'startUnit': 1,
                'endUnit': 2,
                'weekIndexes': [1],
              },
            ],
            'arrangedLessonSearchVms': [
              {
                'id': 10,
                'code': 'L10',
                'course': {
                  'nameZh': '专业综合设计',
                  'code': '020612',
                  'credits': 2.0,
                  'courseType': {'nameZh': '集中实践教学环节'},
                  'defaultOpenDepart': {'nameZh': '电子电气工程学院'},
                  'defaultExamMode': null,
                  'lessonType': '理论课  实验课 ',
                  'periodInfo': {
                    'total': 60.0,
                    'weeks': 2,
                    'theory': 0.0,
                    'experiment': 60.0,
                  },
                },
              },
              {
                'id': 11,
                'code': 'L11',
                'course': {
                  'nameZh': '形势与政策',
                  'code': '229607',
                  'credits': 0.25,
                  'courseType': {'nameZh': '公共基础必修课'},
                  'defaultOpenDepart': {'nameZh': '马克思主义学院'},
                  'defaultExamMode': {'nameZh': '考查'},
                  'lessonType': '理论课 实践课 ',
                  'periodInfo': {'total': 8.0, 'weeks': 4, 'theory': 7.0},
                },
              },
            ],
            'lessonSearchVms': [
              {
                'id': 10,
                'code': 'L10',
                'course': {
                  'nameZh': '专业综合设计',
                  'code': '020612',
                  'credits': 2.0,
                  'courseType': {'nameZh': '集中实践教学环节'},
                  'defaultOpenDepart': {'nameZh': '电子电气工程学院'},
                  'defaultExamMode': {'nameZh': '考试'},
                  'lessonType': '理论课 实验课 ',
                  'periodInfo': {'total': 60.0, 'weeks': 2},
                },
              },
            ],
          },
        ],
      };

      final catalog = FetchCourseService.parseCourseCatalog(
        json,
        7,
        '2026-2027学年第1学期',
      );
      final scheduleRecords = FetchCourseService.parseCourseData(json, 7);

      expect(catalog.tableId, 7);
      expect(catalog.totalCredits, 2.25);
      expect(catalog.courses, hasLength(2));
      expect(scheduleRecords, hasLength(1));

      final design = catalog.courses.firstWhere(
        (course) => course.courseCode == '020612',
      );
      expect(design.examMode, '考试');
      expect(design.teachingFormat, '理论课、实验课');
      expect(design.periodInfo.total, 60);
      expect(design.periodInfo.weeks, 2);
      expect(design.periodInfo.theory, 0);
      expect(design.periodInfo.experiment, 60);
    },
  );

  test(
    'course catalog falls back to summed credits when summary is absent',
    () {
      final catalog = FetchCourseService.parseCourseCatalog(
        {
          'studentTableVms': [
            {
              'arrangedLessonSearchVms': [
                {
                  'id': 1,
                  'course': {'nameZh': 'A', 'code': 'A', 'credits': 0.25},
                },
                {
                  'id': 2,
                  'course': {'nameZh': 'B', 'code': 'B', 'credits': 2},
                },
              ],
            },
          ],
        },
        1,
        'Semester',
      );

      expect(catalog.totalCredits, 2.25);
    },
  );
}
