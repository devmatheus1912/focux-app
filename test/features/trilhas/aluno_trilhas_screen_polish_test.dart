import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('aluno trilhas cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/trilhas/screens/aluno_trilhas_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('trilhasMinhasProvider'));
    expect(screen, isNot(contains("'/api/trilhas/minhas'")));
    expect(screen, contains('PopScope'));
    expect(screen, contains('AlunoSegmentedChoice'));
    expect(screen, contains("safePopOrGo(context, '/dashboard/aluno')"));
    expect(screen, contains("'/checkin/treinos'"));
    expect(screen, contains("label: 'Início'"));
    expect(screen, contains("'/aluno/habitos'"));
    expect(screen, contains("'/chat/aluno'"));
    expect(screen, contains('trilhaListaPrazoValue'));
    expect(screen, contains('concluirMarco'));
    expect(screen, contains('Carregar mais'));
    expect(screen, contains('subtitle: freshness'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('showAlunoTrilhasHelpSheet'));
    expect(screen, isNot(contains('criarTrilha')));
    expect(screen, isNot(contains('deletar')));
    expect(screen, isNot(contains('FloatingActionButton')));
  });
}
