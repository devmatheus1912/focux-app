import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('trilhas cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/trilhas/screens/trilhas_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('showFxFormSheet'));
    expect(screen, contains('ShellHeaderIconButton'));
    expect(screen, contains('LinearProgressIndicator'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('AlunoSegmentedChoice'));
    expect(screen, contains("'Atribuir trilha'"));
    expect(screen, contains('atualizarProgresso'));
    expect(screen, contains('adicionarMarco'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains("safePopOrGo(context, '/alunos/\${widget.alunoId}')"));
    expect(screen, contains('PopScope'));
    expect(screen, contains('/alunos/\$alunoId/chat'));
    expect(screen, contains('/alunos/\$alunoId/evolucao'));
    expect(screen, contains("label: 'Lista'"));
    expect(screen, contains('trilhaListaPrazoValue'));
    expect(screen, contains('Carregar mais'));
    expect(screen, contains('page:'));
    expect(screen, contains('trilhaPrazoIso'));
    expect(screen, contains('subtitle: freshness'));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
  });
}
