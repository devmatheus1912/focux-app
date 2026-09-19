import 'dart:io';

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

    expect(shell, contains('openNovaMensalidade'));
    expect(shell, contains('novaMensalidadeToken'));
    expect(shell, contains('alunosProvider.future'));
    expect(tab, contains('novaMensalidadeToken'));
    expect(tab, contains('_scheduleNovaMensalidadeIfNeeded'));
    expect(tab, contains('FxEmptyAction'));
    expect(tab, contains("'Nova mensalidade'"));
    expect(tab, contains('class FinanceiroMensalidadesTab'));
    expect(tab, contains('FxSatelliteListTile'));
    expect(tab, contains('ListView.builder'));
    expect(tab, contains('DashboardHomeActionChip'));
    expect(tab, contains('loadingLabel:'));
    expect(tab, isNot(contains("'Lançando…' : 'Confirmar'")));
    expect(tab, contains('showFxConfirmSheet'));
    expect(tab, contains('pickMensalidadeMesReferencia'));
    expect(
      File(
        'lib/features/financeiro/utils/mensalidade_surface_actions.dart',
      ).readAsStringSync(),
      allOf(
        contains('showFxInsetPickerSheet'),
        contains('pickMensalidadeVencimento'),
        isNot(contains('showDatePicker')),
      ),
    );
    expect(tab, contains('Carregar mais'));
    expect(tab, contains('marcarLotePago'));
    expect(tab, contains('Marcar lote'));
    expect(tab, contains('RefreshIndicator'));
    expect(tab, contains('onLongPress'));
    expect(tab, contains('_onPullRefresh'));
    expect(tab, contains('atualizarAtrasos'));
    expect(tab, contains('alunosProvider.future'));
    expect(tab, contains('initialAlunoId'));
    expect(tab, contains('FxErrorState'));
    expect(tab, contains('FeedbackHelper.showSuccess'));
    expect(tab, isNot(contains('class _MiniAction')));
    expect(tab, isNot(contains('FloatingActionButton')));
    expect(tab, isNot(contains('check-circle')));
    expect(tab, isNot(contains('DropdownButtonFormField')));
    expect(tab, isNot(contains('Clipboard.setData')));
    expect(tab, isNot(contains('ref.watch(alunosProvider).when(')));

    final dashboard = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_dashboard_screen.dart',
    );
    final resumo = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_resumo_screen.dart',
    );
    expect(dashboard, contains('FinanceiroResumoScreen'));
    expect(dashboard, contains('financeiroPanoramaExtras'));
    expect(dashboard, contains("'Mais no panorama'"));
    expect(dashboard, contains('SmartPricingCard'));
    expect(resumo, contains('emphasize: true'));
    expect(
      resumo,
      anyOf(contains('Ver mensalidades'), contains('Abrir atrasadas')),
    );
    expect(resumo, contains('FxStripCard'));
    expect(resumo, isNot(contains('PieChart')));
    expect(resumo, isNot(contains('_DonutChartCard')));
    expect(tab, contains('FxKeyboardPopScope'));
    expect(tab, contains('FxKeyboardDismissScope'));
  });

  test('mensalidade detalhe busca por id sem extra', () {
    final repo = readScreenSourceBundle(
      'lib/features/financeiro/data/financeiro_repository.dart',
    );
    final router = readScreenSourceBundle(
      'lib/core/router/app_router_chrome_routes.dart',
    );
    expect(repo, contains('/api/financeiro/lote/marcar-pago'));
    expect(repo, contains('mensalidadeIds'));
    expect(repo, contains("get('/api/financeiro/mensalidades/\$id')"));
    expect(repo, contains('Future<Mensalidade> buscar(int id)'));
    expect(repo, contains("j['contatos']"));
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
    expect(detail, contains('FxHubHeader'));
    expect(detail, contains('onTitleTap'));
    expect(detail, contains('FxHelpIconButton'));
    expect(detail, contains('safePopOrGo'));
    expect(detail, contains('OperationalMetricTile'));
    expect(detail, contains('confirmarPagarMensalidade'));
    expect(detail, contains('mostrarPixMensalidade'));
    expect(detail, contains('cobrarMensalidadeViaChat'));
    expect(detail, contains('registrarContatoMensalidade'));
    expect(detail, contains('showEditarMensalidadeSheet'));
    expect(detail, contains('viewInsetsOf'));
    expect(detail, contains('FxContentWidthLimiter'));
    expect(detail, contains('RefreshIndicator'));
    expect(detail, contains('financeiroMensalidadeHubSubtitle'));
    expect(detail, contains('Abrir aluno'));
    expect(detail, contains("'/financeiro'"));
    expect(detail, contains('financeiroMensalidadePagoEmLabel'));
    expect(detail, contains("label: 'Vencimento'"));
    expect(detail, isNot(contains('freshness: freshnessLabel')));
    expect(detail, contains('financeiroMensalidadeVencimentoLabel'));
    expect(detail, contains('mensalidadeDetailMaisActions'));
    expect(detail, contains('Mais ações'));
    expect(detail, contains('listarContatos'));
    expect(detail, contains('loaded.contatos'));
    expect(detail, isNot(contains('AlunoSegmentedChoice')));
    expect(detail, isNot(contains('financeiroMensalidadeDetalheSecoes')));
    expect(detail, contains("'/alunos/\${m.alunoId}'"));
    expect(detail, contains('PopScope'));
    expect(detail, contains('FxEmptyState'));
    expect(detail, isNot(contains("context.pop('pay')")));
    expect(detail, isNot(contains('FxSettingsGroup')));
    final actions = readScreenSourceBundle(
      'lib/features/financeiro/utils/mensalidade_surface_actions.dart',
    );
    expect(actions, contains('copySensitiveToClipboard'));
    expect(actions, contains('showFxConfirmSheet'));
    expect(actions, contains('FxLiquidPrimaryButton'));
    expect(actions, contains('/perfil/wallet'));
    expect(actions, contains('precisaCarteira'));
    expect(actions, contains('Gerando PIX'));
    expect(actions, isNot(contains("'Salvando…' : 'Confirmar'")));
  });
}
