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
}
