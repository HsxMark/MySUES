import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/theme/course_palette.dart';

void main() {
  group('CoursePalette', () {
    test('classic palette matches the academic import order', () {
      expect(CoursePalette.classicHexes, const [
        '#2196F3',
        '#F44336',
        '#4CAF50',
        '#FF9800',
        '#9C27B0',
        '#009688',
        '#E91E63',
        '#3F51B5',
        '#00BCD4',
        '#795548',
      ]);
    });

    test('morandi palette has 12 colors and no duplicates', () {
      expect(CoursePalette.morandi, hasLength(12));
      expect(CoursePalette.morandiHexes.toSet(), hasLength(12));
    });

    test('preset groups do not share colors', () {
      final overlap = CoursePalette.classicHexes.toSet().intersection(
        CoursePalette.morandiHexes.toSet(),
      );
      expect(overlap, isEmpty);
    });

    test('default color stays the first classic color', () {
      expect(CoursePalette.defaultHex, '#2196F3');
    });
  });

  group('courseColorToHex', () {
    test('formats colors as uppercase six digit hex', () {
      expect(courseColorToHex(const Color(0xFF2196F3)), '#2196F3');
      expect(courseColorToHex(const Color(0xFF0A0B0C)), '#0A0B0C');
    });

    test('drops the alpha channel', () {
      expect(courseColorToHex(const Color(0x80123456)), '#123456');
    });

    test('round trips every preset color', () {
      for (final color in CoursePalette.all) {
        final hex = courseColorToHex(color);
        expect(normalizeCourseColorHex(hex), hex);
        expect(courseColorFromHex(hex)?.toARGB32(), color.toARGB32());
      }
    });
  });

  group('courseColorFromHex', () {
    test('accepts six and eight digit values with or without a hash', () {
      expect(courseColorFromHex('#A8707A')?.toARGB32(), 0xFFA8707A);
      expect(courseColorFromHex('a8707a')?.toARGB32(), 0xFFA8707A);
      expect(courseColorFromHex('#FFA8707A')?.toARGB32(), 0xFFA8707A);
      expect(courseColorFromHex(' ffa8707a ')?.toARGB32(), 0xFFA8707A);
    });

    test('rejects malformed values', () {
      expect(courseColorFromHex(null), isNull);
      expect(courseColorFromHex(''), isNull);
      expect(courseColorFromHex('#12345'), isNull);
      expect(courseColorFromHex('#1234567'), isNull);
      expect(courseColorFromHex('#GGGGGG'), isNull);
      expect(courseColorFromHex('not a color'), isNull);
    });
  });

  group('normalizeCourseColorHex', () {
    test('uppercases and expands shorthand input', () {
      expect(normalizeCourseColorHex('#a8707a'), '#A8707A');
      expect(normalizeCourseColorHex(' 7e93a8 '), '#7E93A8');
      expect(normalizeCourseColorHex('#FF7E93A8'), '#7E93A8');
    });

    test('returns null for malformed values', () {
      expect(normalizeCourseColorHex('zzzzzz'), isNull);
      expect(normalizeCourseColorHex(null), isNull);
    });
  });
}
