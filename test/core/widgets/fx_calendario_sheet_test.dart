import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_calendario_sheet.dart';

void main() {
  final primeiro = DateTime(2026, 11, 10);
  final ultimo = DateTime(2027, 5, 10);

  test('abre no dia atual quando está dentro dos limites', () {
    expect(
      fxCalendarioInicial(DateTime(2026, 12, 3, 18), primeiro, ultimo),
      DateTime(2026, 12, 3),
    );
  });

  test('data antiga ou além do limite abre no limite mais perto', () {
    expect(fxCalendarioInicial(DateTime(2026, 1, 1), primeiro, ultimo), primeiro);
    expect(fxCalendarioInicial(DateTime(2028, 1, 1), primeiro, ultimo), ultimo);
    expect(fxCalendarioInicial(null, primeiro, ultimo), primeiro);
  });
}
