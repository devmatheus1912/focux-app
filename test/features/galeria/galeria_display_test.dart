import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/galeria/utils/galeria_display.dart';

void main() {
  test('galeriaCountLabel', () {
    expect(galeriaCountLabel(0), 'Nenhuma foto');
    expect(galeriaCountLabel(1), '1 de 9 fotos');
    expect(galeriaCountLabel(4), '4 de 9 fotos');
    expect(galeriaMaxFotos, 9);
    expect(galeriaLimitLabel(), contains('9'));
  });
}
