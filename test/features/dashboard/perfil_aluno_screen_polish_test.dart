import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('perfil aluno hub é S2 inset sem form nem KPI', () {
    final screen = readScreenSourceBundle(
      'lib/features/dashboard/screens/perfil_aluno_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxSettingsTile'));
    expect(screen, contains('alunoPerfilHomeProvider'));
    expect(screen, contains('completionPercent'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains("label: 'Editar cadastro'"));
    expect(screen, contains("label: 'Anamnese'"));
    expect(screen, contains("label: 'Excluir minha conta'"));
    expect(screen, contains('/aluno/perfil/editar'));
    expect(screen, isNot(contains('onBack:')));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('_MetricHighlightCard')));
    expect(screen, isNot(contains('minhasMedidasProvider')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });

  test('perfil aluno editar é S5 com voltar e salvar', () {
    final screen = readScreenSourceBundle(
      'lib/features/dashboard/screens/perfil_aluno_editar_screen.dart',
    );
    expect(screen, contains('safePopOrGo(context, \'/aluno/perfil\')'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('alunoPerfilHomeProvider'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('showFxHomeSheet'));
    expect(screen, isNot(contains('showModalBottomSheet')));
    expect(screen, isNot(contains('_MetricHighlightCard')));
  });
}
