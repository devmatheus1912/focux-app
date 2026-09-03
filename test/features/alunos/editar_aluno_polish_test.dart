import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('editar aluno usa polish: inset, a11y e save no header', () {
    final screen = readScreenSourceBundle(
      'lib/features/alunos/screens/editar_aluno_screen.dart',
    );

    expect(screen, contains('editarAlunoHubSubtitle()'));
    expect(screen, isNot(contains('ShellHeaderIconButton')));
    expect(screen, isNot(contains("icon: 'circle-check'")));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('showEditarAlunoHelpSheet'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('AlunoInsetFormField'));
    expect(screen, contains('AlunoSegmentedChoice'));
    expect(screen, contains('invalidateAluno360Providers'));
    expect(screen, contains('ListenableBuilder'));
    expect(screen, contains('Salvando alterações do aluno'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('bottomNavigationBar'));
    expect(screen, isNot(contains("subtitle: 'ALUNO'")));
    expect(screen, isNot(contains('ElevatedButton')));
  });
}
