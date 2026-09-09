import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/birth_date_api_format.dart';

void main() {
  test('normalizeBirthDateForApi keeps ISO', () {
    expect(normalizeBirthDateForApi('1995-12-19'), '1995-12-19');
  });

  test('normalizeBirthDateForApi accepts compact digits', () {
    expect(normalizeBirthDateForApi('19121995'), '1995-12-19');
  });

  test('normalizeBirthDateForApi accepts Brazilian slash', () {
    expect(normalizeBirthDateForApi('19/12/1995'), '1995-12-19');
  });

  test('formatBirthDateForDisplay usa dd-MM-yyyy', () {
    expect(formatBirthDateForDisplay('1995-12-19'), '19-12-1995');
  });
}
