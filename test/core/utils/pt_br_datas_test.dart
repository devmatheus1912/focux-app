import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/pt_br_display.dart';

void main() {
  test('data curta e completa no formato brasileiro', () {
    final d = DateTime(2026, 3, 7);
    expect(dataCurta(d), '07/03');
    expect(dataBr(d), '07/03/2026');
  });
}
