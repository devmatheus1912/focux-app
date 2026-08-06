import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/br_phone.dart';

void main() {
  group('BrPhone', () {
    test('normalizeOrNull strips mask', () {
      expect(BrPhone.normalizeOrNull('(11) 99999-0000'), '11999990000');
      expect(BrPhone.normalizeOrNull('  '), isNull);
      expect(BrPhone.normalizeOrNull(null), isNull);
    });

    test('validateOptional accepts empty and valid BR phones', () {
      expect(BrPhone.validateOptional(''), isNull);
      expect(BrPhone.validateOptional('(11) 99999-0000'), isNull);
      expect(BrPhone.validateOptional('11 3333-4444'), isNull);
      expect(BrPhone.validateOptional('123'), isNotNull);
    });
  });
}
