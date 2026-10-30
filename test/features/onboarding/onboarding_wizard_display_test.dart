import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/onboarding/data/onboarding_repository.dart';
import 'package:focux_app/features/onboarding/utils/onboarding_wizard_display.dart';

void main() {
  OnboardingStep passo(String id, {bool feito = false}) => OnboardingStep(
    id: id,
    title: id,
    description: '',
    icon: '',
    completed: feito,
    actionRoute: '/',
    estimatedMinutes: 1,
  );

  test('botão diz a ação do passo atual', () {
    expect(
      wizardStickyLabel(allDone: false, steps: [passo('primeiro-aluno')]),
      'Cadastrar aluno',
    );
    expect(
      wizardStickyLabel(
        allDone: false,
        steps: [passo('primeiro-aluno', feito: true), passo('primeiro-treino')],
      ),
      'Criar treino',
    );
    expect(wizardStickyLabel(allDone: true, steps: const []), 'Concluir');
  });

}
