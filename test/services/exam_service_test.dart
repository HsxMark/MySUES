import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/models/exam.dart';
import 'package:mysues/services/exam_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('clearFinishedExams removes normalized finished statuses', () async {
    await ExamService.saveExams([
      Exam(
        courseName: 'Chinese',
        timeString: '2099-01-01 08:00~10:00',
        location: 'A101',
        type: '期末',
        status: '已结束',
      ),
      Exam(
        courseName: 'English',
        timeString: '2099-01-02 08:00~10:00',
        location: 'A102',
        type: 'Final',
        status: 'Finished',
      ),
      Exam(
        courseName: 'Ended',
        timeString: '2099-01-03 08:00~10:00',
        location: 'A103',
        type: 'Final',
        status: 'Ended',
      ),
      Exam(
        courseName: 'Completed',
        timeString: '2099-01-04 08:00~10:00',
        location: 'A104',
        type: 'Final',
        status: 'Completed',
      ),
      Exam(
        courseName: 'Upcoming',
        timeString: '2099-01-05 08:00~10:00',
        location: 'A105',
        type: 'Final',
        status: 'Upcoming',
      ),
    ]);

    await ExamService.clearFinishedExams();

    final remaining = await ExamService.loadExams();
    expect(remaining, hasLength(1));
    expect(remaining.single.courseName, 'Upcoming');
  });
}
