import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/onboarding/utils/onboarding_wizard_display.dart';

void main() {
  test('sticky distingue continuar e concluir', () {
    expect(wizardStickyLabel(allDone: false), 'Continuar');
    expect(wizardStickyLabel(allDone: true), 'Concluir');
  });

  test('copy de concluir não promete apagar dados', () {
    expect(wizardConfirmMessage(), contains('Home'));
    expect(wizardHelpConcluirBody().toLowerCase(), isNot(contains('apaga')));
  });

  test('etapa é discreta e 1-based nos pendentes', () {
    expect(
      wizardEtapaLabel(completedCount: 1, totalCount: 4, allDone: false),
      'Etapa 2 de 4',
    );
    expect(
      wizardEtapaLabel(completedCount: 4, totalCount: 4, allDone: true),
      'Etapa 4 de 4',
    );
    expect(
      wizardTitlesCaption(prefix: 'Já feito:', titles: ['Perfil', 'Aluno']),
      'Já feito: Perfil, Aluno',
    );
    expect(wizardTitlesCaption(prefix: 'Depois:', titles: const []), '');
  });
}
