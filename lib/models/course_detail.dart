class CoursePeriodInfo {
  final double? total;
  final int? weeks;
  final double? theory;
  final double? practice;
  final double? focusPractice;
  final double? dispersedPractice;
  final double? test;
  final double? experiment;
  final double? machine;
  final double? design;
  final double? extra;

  const CoursePeriodInfo({
    this.total,
    this.weeks,
    this.theory,
    this.practice,
    this.focusPractice,
    this.dispersedPractice,
    this.test,
    this.experiment,
    this.machine,
    this.design,
    this.extra,
  });

  factory CoursePeriodInfo.fromJson(Map<String, dynamic> json) {
    return CoursePeriodInfo(
      total: _toDouble(json['total']),
      weeks: _toInt(json['weeks']),
      theory: _toDouble(json['theory']),
      practice: _toDouble(json['practice']),
      focusPractice: _toDouble(json['focusPractice']),
      dispersedPractice: _toDouble(json['dispersedPractice']),
      test: _toDouble(json['test']),
      experiment: _toDouble(json['experiment']),
      machine: _toDouble(json['machine']),
      design: _toDouble(json['design']),
      extra: _toDouble(json['extra']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'weeks': weeks,
      'theory': theory,
      'practice': practice,
      'focusPractice': focusPractice,
      'dispersedPractice': dispersedPractice,
      'test': test,
      'experiment': experiment,
      'machine': machine,
      'design': design,
      'extra': extra,
    };
  }

  CoursePeriodInfo mergeMissing(CoursePeriodInfo fallback) {
    return CoursePeriodInfo(
      total: total ?? fallback.total,
      weeks: weeks ?? fallback.weeks,
      theory: theory ?? fallback.theory,
      practice: practice ?? fallback.practice,
      focusPractice: focusPractice ?? fallback.focusPractice,
      dispersedPractice: dispersedPractice ?? fallback.dispersedPractice,
      test: test ?? fallback.test,
      experiment: experiment ?? fallback.experiment,
      machine: machine ?? fallback.machine,
      design: design ?? fallback.design,
      extra: extra ?? fallback.extra,
    );
  }
}

class CourseDetail {
  final String sourceKey;
  final int? lessonId;
  final String courseName;
  final String courseCode;
  final String courseType;
  final String examMode;
  final String openDepartment;
  final String teachingFormat;
  final double credits;
  final CoursePeriodInfo periodInfo;

  const CourseDetail({
    required this.sourceKey,
    this.lessonId,
    required this.courseName,
    required this.courseCode,
    required this.courseType,
    required this.examMode,
    required this.openDepartment,
    required this.teachingFormat,
    required this.credits,
    required this.periodInfo,
  });

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    final periodJson = json['periodInfo'];
    return CourseDetail(
      sourceKey: json['sourceKey']?.toString() ?? '',
      lessonId: _toInt(json['lessonId']),
      courseName: json['courseName']?.toString() ?? '',
      courseCode: json['courseCode']?.toString() ?? '',
      courseType: json['courseType']?.toString() ?? '',
      examMode: json['examMode']?.toString() ?? '',
      openDepartment: json['openDepartment']?.toString() ?? '',
      teachingFormat: json['teachingFormat']?.toString() ?? '',
      credits: _toDouble(json['credits']) ?? 0,
      periodInfo: periodJson is Map<String, dynamic>
          ? CoursePeriodInfo.fromJson(periodJson)
          : CoursePeriodInfo.fromJson(
              Map<String, dynamic>.from(periodJson as Map? ?? const {}),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceKey': sourceKey,
      'lessonId': lessonId,
      'courseName': courseName,
      'courseCode': courseCode,
      'courseType': courseType,
      'examMode': examMode,
      'openDepartment': openDepartment,
      'teachingFormat': teachingFormat,
      'credits': credits,
      'periodInfo': periodInfo.toJson(),
    };
  }

  CourseDetail mergeMissing(CourseDetail fallback) {
    return CourseDetail(
      sourceKey: sourceKey.isNotEmpty ? sourceKey : fallback.sourceKey,
      lessonId: lessonId ?? fallback.lessonId,
      courseName: _preferText(courseName, fallback.courseName),
      courseCode: _preferText(courseCode, fallback.courseCode),
      courseType: _preferText(courseType, fallback.courseType),
      examMode: _preferText(examMode, fallback.examMode),
      openDepartment: _preferText(openDepartment, fallback.openDepartment),
      teachingFormat: _preferText(teachingFormat, fallback.teachingFormat),
      credits: credits != 0 ? credits : fallback.credits,
      periodInfo: periodInfo.mergeMissing(fallback.periodInfo),
    );
  }
}

class SemesterCourseCatalog {
  final int tableId;
  final String semesterName;
  final double totalCredits;
  final List<CourseDetail> courses;

  const SemesterCourseCatalog({
    required this.tableId,
    required this.semesterName,
    required this.totalCredits,
    required this.courses,
  });

  factory SemesterCourseCatalog.fromJson(Map<String, dynamic> json) {
    final rawCourses = json['courses'] as List? ?? const [];
    return SemesterCourseCatalog(
      tableId: _toInt(json['tableId']) ?? 0,
      semesterName: json['semesterName']?.toString() ?? '',
      totalCredits: _toDouble(json['totalCredits']) ?? 0,
      courses: rawCourses
          .whereType<Map>()
          .map((item) => CourseDetail.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tableId': tableId,
      'semesterName': semesterName,
      'totalCredits': totalCredits,
      'courses': courses.map((course) => course.toJson()).toList(),
    };
  }

  SemesterCourseCatalog copyWith({
    int? tableId,
    String? semesterName,
    double? totalCredits,
    List<CourseDetail>? courses,
  }) {
    return SemesterCourseCatalog(
      tableId: tableId ?? this.tableId,
      semesterName: semesterName ?? this.semesterName,
      totalCredits: totalCredits ?? this.totalCredits,
      courses: courses ?? this.courses,
    );
  }
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _preferText(String value, String fallback) {
  return value.trim().isNotEmpty ? value : fallback;
}
