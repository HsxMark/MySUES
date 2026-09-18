import 'package:flutter_test/flutter_test.dart';
import 'package:mysues/utils/profile_preference_keys.dart';

void main() {
  test('grade overrides are scoped by student ID', () {
    expect(
      ProfilePreferenceKeys.gradeOverride('021123001'),
      isNot(ProfilePreferenceKeys.gradeOverride('021124001')),
    );
  });
}
