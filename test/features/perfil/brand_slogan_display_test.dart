import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/utils/brand_slogan_display.dart';

void main() {
  test('formatBrandSloganForDisplay corrige atraves sem acento', () {
    expect(
      formatBrandSloganForDisplay(
        'Transformando vida atraves de movimento',
      ),
      'Transformando vida através de movimento',
    );
    expect(formatBrandSloganForDisplay('Atraves do treino'), 'Através do treino');
    expect(formatBrandSloganForDisplay('ATRAVES'), 'ATRAVÉS');
    expect(formatBrandSloganForDisplay(''), '');
    expect(
      formatBrandSloganForDisplay('Já com acento através'),
      'Já com acento através',
    );
  });
}
