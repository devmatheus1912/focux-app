import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/fx_utils.dart';

void main() {
  group('fxDateFull', () {
    test('formats date in full Portuguese', () {
      final d = DateTime(2026, 5, 4);
      expect(fxDateFull(d), '4 de maio de 2026');
    });

    test('january', () {
      expect(fxDateFull(DateTime(2026, 1, 15)), '15 de janeiro de 2026');
    });
  });

  group('fxDateShort', () {
    test('pads day and month', () {
      expect(fxDateShort(DateTime(2026, 5, 4)), '04/05');
    });

    test('two digit day', () {
      expect(fxDateShort(DateTime(2026, 12, 25)), '25/12');
    });
  });

  group('fxMonthYear', () {
    test('abbreviates month and appends year', () {
      expect(fxMonthYear(DateTime(2026, 5, 1)), 'Mai 2026');
    });

    test('january', () {
      expect(fxMonthYear(DateTime(2026, 1, 1)), 'Jan 2026');
    });
  });
}
