import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/onboarding/utils/onboarding_wizard_display.dart';

void main() {
  test('concluído diz "3 de 3 feitos", não "Etapa 3 de 3"', () {
    expect(
      wizardEtapaLabel(completedCount: 3, totalCount: 3, allDone: true),
      '3 de 3 feitos',
    );
    expect(
      wizardEtapaLabel(completedCount: 1, totalCount: 3, allDone: false),
      'Etapa 2 de 3',
    );
  });

  test('o fim aponta o próximo passo', () {
    expect(wizardProximoPasso(), startsWith('Próximo:'));
  });
}
