import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('financeiro usa polish: shell fino e lista inset', () {
    final shell = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_screen.dart',
    );
    final tab = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_mensalidades_tab.dart',
    );

    expect(shell, contains('FinanceiroMensalidadesTab'));
    expect(shell, contains('FxHubFreshness'));
    expect(shell, contains('seedFromHome'));
    expect(shell, contains('IndexedStack'));
    expect(shell, isNot(contains('TabBarView')));
    expect(shell, isNot(contains('class _MensalidadesTab')));
    expect(shell, isNot(contains('_MiniAction')));

    expect(tab, contains('class FinanceiroMensalidadesTab'));
    expect(tab, contains('FxSatelliteListTile'));
    expect(tab, contains('ListView.builder'));
    expect(tab, contains('FxLiquidPrimaryButton'));
    expect(tab, contains('showFxConfirmSheet'));
    expect(tab, contains('copySensitiveToClipboard'));
    expect(tab, contains('Carregar mais'));
    expect(tab, contains('FxErrorState'));
    expect(tab, contains('FeedbackHelper.showSuccess'));
    expect(tab, isNot(contains('class _MiniAction')));
    expect(tab, isNot(contains('FloatingActionButton')));
    expect(tab, isNot(contains('check-circle')));
    expect(tab, isNot(contains('DropdownButtonFormField')));
    expect(tab, isNot(contains('Clipboard.setData')));
  });

  test('mensalidade detalhe busca por id sem extra', () {
    final repo = readScreenSourceBundle(
      'lib/features/financeiro/data/financeiro_repository.dart',
    );
    final router = readScreenSourceBundle(
      'lib/core/router/app_router_chrome_routes.dart',
    );
    expect(repo, contains("get('/api/financeiro/mensalidades/\$id')"));
    expect(repo, contains('Future<Mensalidade> buscar(int id)'));
    expect(router, contains('FinanceiroMensalidadeDetailScreen('));
    expect(router, contains('mensalidadeId: id'));
    expect(router, isNot(contains("extra is! Mensalidade")));
  });

  test('mensalidade detalhe é S3 com sticky transacional', () {
    final detail = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_mensalidade_detail_screen.dart',
    );
    expect(detail, contains('FxLiquidPrimaryButton'));
    expect(detail, contains('Marcar como paga'));
    expect(detail, contains('OperationalMetricTile'));
    expect(detail, isNot(contains('FxSettingsGroup')));
  });
}
