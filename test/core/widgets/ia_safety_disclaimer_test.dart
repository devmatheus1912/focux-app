import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/ia_safety_disclaimer.dart';

void main() {
  test('tela do personal não manda procurar outro profissional', () {
    expect(IaSafetyDisclaimer.defaultText, contains('Revise antes de aplicar'));
    expect(IaSafetyDisclaimer.defaultText, isNot(contains('nutricionista')));
    expect(IaSafetyDisclaimer.defaultText, isNot(contains('especialista')));
  });

  test('PDF assina pelo personal', () {
    expect(
      iaPdfDisclaimer('Carla Mendes'),
      'Plano revisado por Carla Mendes. Gerado com apoio de IA.',
    );
    expect(
      iaPdfDisclaimer('  '),
      'Plano revisado pelo seu personal. Gerado com apoio de IA.',
    );
    expect(iaPdfDisclaimer(null), contains('seu personal'));
  });
}
