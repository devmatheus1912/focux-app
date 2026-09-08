import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../alunos/widgets/aluno_outreach_message_sheet.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/relatorio_repository.dart';
import '../utils/relatorio_aluno_display.dart';
import '../utils/relatorio_global_display.dart';
import '../utils/relatorio_pdf_export.dart';
import '../widgets/relatorio_aluno_help_sheet.dart';

class RelatorioScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;

  const RelatorioScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends ConsumerState<RelatorioScreen> {
  final _openedAt = DateTime.now();
  var _dias = 30;
  DateTimeRange? _rangeCustom;
  AderenciaData? _dados;
  ComparativoPeriodo? _comparativo;
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  var _viewTracked = false;
  var _ttvTracked = false;
  var _exporting = false;
  var _secao = relatorioDetalheSecaoResumo;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final home = await RelatorioRepository(
        ref.read(apiClientProvider),
      ).getHome(
        widget.alunoId,
        dias: _dias,
        inicio: _rangeCustom?.start,
        fim: _rangeCustom?.end,
      );
      if (!mounted) return;
      setState(() {
        _dados = home.aderencia;
        _comparativo = home.comparativo;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
      _trackViewIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  void _trackViewIfNeeded() {
    if (_viewTracked) return;
    _viewTracked = true;
    AnalyticsService.instance.track(
      ProductEvents.relatorioAlunoViewed,
      props: {'aluno_id': widget.alunoId, 'dias': _dias},
    );
    if (!_ttvTracked) {
      _ttvTracked = true;
      AnalyticsService.instance.track(
        ProductEvents.relatorioAlunoTtv,
        props: {
          'ms': DateTime.now().difference(_openedAt).inMilliseconds,
          'aluno_id': widget.alunoId,
        },
      );
    }
  }

  Future<void> _abrirPeriodo() async {
    final selected = relatorioAlunoPeriodoKey(
      dias: _dias,
      personalizado: _rangeCustom != null,
    );
    final picked = await showFxInsetPickerSheet<String>(
      context,
      title: 'Período',
      headerIcon: Icons.calendar_today_outlined,
      selected: selected,
      items: [
        for (final key in relatorioAlunoPeriodoKeys)
          FxInsetPickerSheetItem(
            value: key,
            label: relatorioAlunoPeriodoOpcaoLabel(key),
          ),
      ],
    );
    if (!mounted || picked == null || picked == selected) return;
    if (picked == 'custom') {
      await _escolherPeriodoCustom();
      return;
    }
    final dias = relatorioAlunoDiasFromKey(picked);
    if (dias == null) return;
    setState(() {
      _dias = dias;
      _rangeCustom = null;
    });
    await _carregarDados();
  }

  Future<void> _escolherPeriodoCustom() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      initialDateRange:
          _rangeCustom ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (!mounted || range == null) return;
    FxKeyboardDismissScope.dismiss();
    setState(() => _rangeCustom = range);
    await _carregarDados();
  }

  Future<void> _exportarPdf() async {
    final dados = _dados;
    if (dados == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      await exportRelatorioPdf(
        alunoNome: widget.alunoNome,
        periodoLabel: relatorioPeriodoLabelPdf(
          dias: _dias,
          rangeCustom:
              _rangeCustom == null
                  ? null
                  : DateTimeRangePdf(
                    start: _rangeCustom!.start,
                    end: _rangeCustom!.end,
                  ),
        ),
        dados: dados,
        comparativo: _comparativo,
      );
      AnalyticsService.instance.track(
        ProductEvents.relatorioAlunoPdfExported,
        props: {'aluno_id': widget.alunoId},
      );
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final dados = _dados;
    final hasData = dados != null && dados.treinosTotal > 0;
    final showSticky = !_loading && _erro == null;

    return fxScreenA11yScope(
      label: 'Relatório — ${widget.alunoNome}',
      child: FeatureGate(
        featureName: 'Relatórios',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'relatorios',
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            safePopOrGo(context, '/alunos/${widget.alunoId}');
          },
          child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Relatório',
            onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como ler este relatório',
                onTap: () {
                  AnalyticsService.instance.track(
                    ProductEvents.relatorioAlunoHelpOpened,
                  );
                  showRelatorioAlunoHelpSheet(context);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: _buildBody(isDark: isDark, primary: primary)),
              if (showSticky)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: Semantics(
                      button: true,
                      label:
                          hasData
                              ? 'Exportar relatório em PDF'
                              : 'Ver evolução do aluno',
                      child: FxLiquidPrimaryButton(
                        label:
                            hasData
                                ? relatorioAlunoStickyExport()
                                : relatorioAlunoStickyEmpty(),
                        loading: hasData && _exporting,
                        onPressed:
                            hasData
                                ? (_exporting ? null : _exportarPdf)
                                : () => context.push(
                                  '/alunos/${widget.alunoId}/evolucao',
                                ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildBody({required bool isDark, required Color primary}) {
    final dados = _dados;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(FxSettingsLayout.pageInset),
        child: SkeletonList(count: 6),
      );
    }
    if (_erro != null) {
      return FxErrorState(
        chromeOnDark: isDark,
        primary: primary,
        title: 'Não conseguimos carregar o relatório',
        message: _erro!,
        onRetry: _carregarDados,
      );
    }
    return RefreshIndicator(
      color: primary,
      onRefresh: () async {
        AnalyticsService.instance.track(ProductEvents.relatorioAlunoRefreshed);
        await _carregarDados();
      },
      child: FxContentWidthLimiter(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            FxSettingsLayout.pageInset,
            TokensStrip.s4,
            FxSettingsLayout.pageInset,
            TokensStrip.s6,
          ),
          children: [
            FxHubHeader(
              title: fxTitleCaseName(widget.alunoNome),
              subtitle: relatorioAlunoHubSubtitle(
                alunoNome: widget.alunoNome,
                diasAnalisados: dados?.diasAnalisados ?? 0,
                freshness: FxHubFreshness.fromFetchedAt(_fetchedAt),
              ),
            ),
            const SizedBox(height: TokensStrip.s3),
            Wrap(
              spacing: TokensStrip.s2,
              runSpacing: TokensStrip.s2,
              children: [
                DashboardHomeActionChip(
                  label: relatorioAlunoPeriodoValueLabel(
                    dias: _dias,
                    inicio: _rangeCustom?.start,
                    fim: _rangeCustom?.end,
                  ),
                  accent: primary,
                  isDark: isDark,
                  onPressed: _abrirPeriodo,
                ),
                DashboardHomeActionChip(
                  label: 'Aluno',
                  accent: primary,
                  isDark: isDark,
                  onPressed:
                      () => context.push('/alunos/${widget.alunoId}'),
                ),
                DashboardHomeActionChip(
                  label: 'Chat',
                  accent: primary,
                  isDark: isDark,
                  onPressed:
                      () => context.push('/alunos/${widget.alunoId}/chat'),
                ),
                if (dados != null &&
                    dados.treinosTotal > 0 &&
                    relatorioAlunoAderenciaBaixa(dados.taxaAderenciaPercent))
                  DashboardHomeActionChip(
                    label: relatorioAlunoCheckinChip(),
                    accent: primary,
                    isDark: isDark,
                    onPressed:
                        () => showAlunoCheckinMessageSheet(
                          context,
                          alunoId: widget.alunoId,
                          alunoNome: widget.alunoNome,
                        ),
                  ),
              ],
            ),
            if (dados == null || dados.treinosTotal == 0) ...[
              const SizedBox(height: TokensStrip.s5),
              FxEmptyState(
                icon: 'trend',
                title: 'Sem dados neste período',
                subtitle:
                    'Quando ${satelliteFirstName(widget.alunoNome)} concluir treinos, o relatório aparece aqui.',
                action: FxEmptyAction(
                  label: 'Atualizar',
                  onTap: _carregarDados,
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(
                  top: TokensStrip.s4,
                  bottom: TokensStrip.s3,
                ),
                child: OperationalMetricTile(
                  label: 'Taxa',
                  value: relatorioAderenciaMediaLabel(dados.taxaAderenciaPercent),
                  hint: relatorioAlunoAderenciaStatus(dados.taxaAderenciaPercent),
                  color:
                      relatorioAlunoAderenciaBaixa(dados.taxaAderenciaPercent)
                          ? EagleTokens.bad
                          : EagleTokens.moneyGreen,
                  isDark: isDark,
                  emphasis:
                      relatorioAlunoAderenciaBaixa(dados.taxaAderenciaPercent)
                          ? OperationalMetricEmphasis.alert
                          : OperationalMetricEmphasis.normal,
                ),
              ),
              OperationalMetricTile(
                label: 'Treinos concluídos',
                value: '${dados.treinosConcluidos} / ${dados.treinosTotal}',
                hint: 'Concluídos sobre o total neste recorte',
                color: primary,
                isDark: isDark,
              ),
              const SizedBox(height: TokensStrip.s4),
              AlunoSegmentedChoice(
                options: relatorioDetalheSecoes,
                selected: _secao,
                isDark: isDark,
                onSelect: (value) => setState(() => _secao = value),
              ),
              if (_secao == relatorioDetalheSecaoComparativo &&
                  _comparativo != null) ...[
                const SizedBox(height: TokensStrip.s2),
                OperationalMetricTile(
                  label: 'Variação',
                  value: relatorioAlunoDeltaLabel(_comparativo!.deltaPercent),
                  hint: 'Mesmo número de dias, logo antes deste',
                  color:
                      _comparativo!.deltaPercent < 0
                          ? EagleTokens.bad
                          : EagleTokens.moneyGreen,
                  isDark: isDark,
                  emphasis:
                      _comparativo!.deltaPercent < 0
                          ? OperationalMetricEmphasis.alert
                          : OperationalMetricEmphasis.normal,
                ),
                const SizedBox(height: TokensStrip.s5),
                const DashboardSectionHeader(title: 'Versus o recorte anterior'),
                const SizedBox(height: TokensStrip.s3),
                FxSatelliteListTile(
                  title: 'Este período',
                  subtitle: Text(
                    '${relatorioAderenciaMediaLabel(_comparativo!.aderenciaAtual)} · ${relatorioAlunoCheckinsLabel(_comparativo!.checkInsAtual)}',
                  ),
                ),
                FxSatelliteListTile(
                  title: 'Anterior',
                  subtitle: Text(
                    '${relatorioAderenciaMediaLabel(_comparativo!.aderenciaAnterior)} · ${relatorioAlunoCheckinsLabel(_comparativo!.checkInsAnterior)}',
                  ),
                ),
              ] else if (_secao == relatorioDetalheSecaoComparativo) ...[
                const SizedBox(height: TokensStrip.s5),
                FxEmptyState(
                  icon: 'trend',
                  title: 'Sem recorte anterior',
                  subtitle:
                      'Com mais história neste aluno, o versus aparece aqui.',
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
