import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('histórico: sessões concluídas por semana e fold antigo fora', () {
    final screen = readScreenSourceBundle(
      'lib/features/checkin/screens/historico_screen.dart',
    );

    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxAsyncBody<HistoricoLista>'));
    expect(screen, contains('skipError: true'));
    expect(screen, contains('historicoListaProvider'));
    expect(screen, contains('agruparHistoricoPorSemana'));
    expect(screen, contains('historicoSemanaCabecalho'));
    expect(screen, contains('TreinoRecenteRow'));
    expect(screen, contains('HistoricoFiltroFichas'));
    expect(screen, contains('HistoricoMaisRodape'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains("fallbackLocation: '/checkin/treinos'"));
    expect(screen, contains('historicoDetalhePath'));

    for (final morto in [
      'HistoricoMemCache',
      'HistoricoDetalheMemCache',
      'TextField',
      'HistoricoStatusChip',
      'historicoCollapseSamePlan',
      'historicoGroupByStatus',
      'historicoStatusQuery',
      'FxHelpIconButton',
      'Carregar mais',
      '_prefetch',
      "'Histórico de Treinos'",
    ]) {
      expect(screen, isNot(contains(morto)), reason: morto);
    }
    for (final apagado in [
      'lib/features/checkin/data/historico_mem_cache.dart',
      'lib/features/checkin/utils/historico_display.dart',
      'lib/features/checkin/utils/historico_sessao_metrics.dart',
    ]) {
      expect(File(apagado).existsSync(), isFalse, reason: apagado);
    }
  });
}
