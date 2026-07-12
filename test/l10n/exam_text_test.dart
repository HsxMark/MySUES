import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/l10n/exam_text.dart';

void main() {
  test('recognizes finished exam status independent of source language', () {
    expect(isFinishedExamStatus('已结束'), isTrue);
    expect(isFinishedExamStatus('Finished'), isTrue);
    expect(isFinishedExamStatus('未开始'), isFalse);
  });

  testWidgets('localizes normalized exam metadata to English', (tester) async {
    late String status;
    late String type;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            status = localizedExamStatus(context, '已结束');
            type = localizedExamType(context, '期末');
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(status, 'Finished');
    expect(type, 'Final');
  });
}
