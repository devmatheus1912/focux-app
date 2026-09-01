import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../alunos/widgets/aluno_outreach_message_sheet.dart';
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
        comparativo:
            relatorioAlunoMostraComparativo(
                  personalizado: _rangeCustom != null,
                )
                ? _comparativo
                : null,
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
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final subtitle =
        freshness == null
            ? widget.alunoNome
            : '${widget.alunoNome} · $freshness';
    final dados = _dados;
    final personalizado = _rangeCustom != null;
    final mostraComparativo = relatorioAlunoMostraComparativo(
      personalizado: personalizado,
    );

    return fxScreenA11yScope(
      label: 'Relatório — ${widget.alunoNome}',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Relatório',
          subtitle: subtitle,
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
        body: _loading
            ? const Padding(
              padding: EdgeInsets.all(FxSettingsLayout.pageInset),
              child: SkeletonList(count: 6),
            )
            : _erro != null
            ? FxErrorState(
              chromeOnDark: isDark,
              primary: primary,
              title: 'Não conseguimos carregar o relatório',
              message: _erro!,
              onRetry: _carregarDados,
            )
            : RefreshIndicator(
              color: primary,
              onRefresh: () async {
                AnalyticsService.instance.track(
                  ProductEvents.relatorioAlunoRefreshed,
                );
                await _carregarDados();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  8,
                  FxSettingsLayout.pageInset,
                  110,
                ),
                children: [
                  FxSettingsGroup(
                    header: 'Período',
                    caption:
                        'O comparativo usa o mesmo tamanho, no recorte anterior.',
                    children: [
                      FxSettingsTile(
                        fxIcon: 'calendar',
                        label: 'Recorte',
                        value: relatorioAlunoPeriodoValueLabel(
                          dias: _dias,
                          inicio: _rangeCustom?.start,
                          fim: _rangeCustom?.end,
                        ),
                        picker: true,
                        showDivider: false,
                        onTap: _abrirPeriodo,
                      ),
                    ],
                  ),
                  if (dados == null || dados.treinosTotal == 0) ...[
                    const SizedBox(height: FxSettingsLayout.groupGap),
                    SizedBox(
                      height: 280,
                      child: FxEmptyState(
                        icon: 'trend',
                        title: 'Sem dados neste período',
                        subtitle:
                            'Quando ${satelliteFirstName(widget.alunoNome)} concluir treinos, o relatório aparece aqui.',
                        action: FxEmptyAction(
                          label: 'Atualizar',
                          onTap: _carregarDados,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: FxSettingsLayout.groupGap),
                    FxSettingsGroup(
                      header: 'Aderência',
                      caption: 'Concluídos sobre o total neste recorte.',
                      children: [
                        FxSettingsTile(
                          fxIcon: 'trend',
                          label: 'Taxa',
                          value: relatorioAderenciaMediaLabel(
                            dados.taxaAderenciaPercent,
                          ),
                          subtitle: relatorioAlunoAderenciaStatus(
                            dados.taxaAderenciaPercent,
                          ),
                          numeric: true,
                          danger: relatorioAlunoAderenciaBaixa(
                            dados.taxaAderenciaPercent,
                          ),
                          onTap: () {},
                        ),
                        FxSettingsTile(
                          fxIcon: 'circle-check',
                          label: 'Treinos concluídos',
                          value:
                              '${dados.treinosConcluidos} / ${dados.treinosTotal}',
                          numeric: true,
                          onTap: () {},
                        ),
                        FxSettingsTile(
                          fxIcon: 'calendar',
                          label: 'Dias analisados',
                          value: '${dados.diasAnalisados}',
                          numeric: true,
                          showDivider: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                    if (mostraComparativo && _comparativo != null) ...[
                      const SizedBox(height: FxSettingsLayout.groupGap),
                      FxSettingsGroup(
                        header: 'Versus o recorte anterior',
                        caption: 'Mesmo número de dias, logo antes deste.',
                        children: [
                          FxSettingsTile(
                            fxIcon: 'trend',
                            label: 'Este período',
                            value: relatorioAderenciaMediaLabel(
                              _comparativo!.aderenciaAtual,
                            ),
                            subtitle: relatorioAlunoCheckinsLabel(
                              _comparativo!.checkInsAtual,
                            ),
                            numeric: true,
                            onTap: () {},
                          ),
                          FxSettingsTile(
                            fxIcon: 'trend',
                            label: 'Anterior',
                            value: relatorioAderenciaMediaLabel(
                              _comparativo!.aderenciaAnterior,
                            ),
                            subtitle: relatorioAlunoCheckinsLabel(
                              _comparativo!.checkInsAnterior,
                            ),
                            numeric: true,
                            onTap: () {},
                          ),
                          FxSettingsTile(
                            fxIcon: 'trend',
                            label: 'Variação',
                            value: relatorioAlunoDeltaLabel(
                              _comparativo!.deltaPercent,
                            ),
                            numeric: true,
                            danger: _comparativo!.deltaPercent < 0,
                            highlight: _comparativo!.deltaPercent > 0,
                            showDivider: false,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: FxSettingsLayout.groupGap),
                    FxSettingsGroup(
                      header: 'Ações',
                      children: [
                        FxSettingsTile(
                          fxIcon: 'article',
                          label: _exporting ? 'Gerando PDF…' : 'Exportar PDF',
                          value: '',
                          semanticsLabel: 'Exportar relatório em PDF',
                          onTap: _exporting ? () {} : _exportarPdf,
                        ),
                        if (relatorioAlunoAderenciaBaixa(
                          dados.taxaAderenciaPercent,
                        ))
                          FxSettingsTile(
                            fxIcon: 'message-circle',
                            label: 'Pedir check-in',
                            value: '',
                            onTap: () => showAlunoCheckinMessageSheet(
                              context,
                              alunoId: widget.alunoId,
                              alunoNome: widget.alunoNome,
                            ),
                          ),
                        FxSettingsTile(
                          fxIcon: 'users',
                          label: 'Abrir o 360',
                          value: '',
                          showDivider: false,
                          onTap: () => context.push(
                            '/alunos/${widget.alunoId}',
                            extra: widget.alunoNome,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
      ),
    );
  }
}
