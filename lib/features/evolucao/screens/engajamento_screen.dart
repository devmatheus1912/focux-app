import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/pdf/focux_pdf_brand_loader.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fx_metric_strip.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../alunos/providers/aluno_detail_providers.dart';
import '../../planos/data/plano_recurso.dart';
import '../../planos/utils/plan_gate.dart';
import '../../relatorio/data/relatorio_repository.dart';
import '../../relatorio/utils/relatorio_pdf_export.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../providers/metas_provider.dart';
import '../utils/engajamento_display.dart';
import '../widgets/engajamento_card_aderencia.dart';
import '../widgets/engajamento_help_sheet.dart';
import '../widgets/engajamento_quadro_semanas.dart';
import '../../../l10n/pt.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../alunos/widgets/aluno360_timeline_full_sheet.dart';
import '../../../core/theme/fx_icons.dart';

class EngajamentoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  final String? initialSection;
  const EngajamentoScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.initialSection,
  });

  @override
  ConsumerState<EngajamentoScreen> createState() => _EngajamentoScreenState();
}

class _EngajamentoScreenState extends ConsumerState<EngajamentoScreen> {
  List<EventoEngajamento> _eventos = [];
  AderenciaResumo? _aderencia;
  DateTime? _fichaDesde;
  AderenciaPeriodo? _periodoDados;
  var _periodo = EngajamentoPeriodo.cincoSemanas;
  bool _loading = true;
  bool _exportando = false;
  String? _erro;
  DateTime? _fetchedAt;
  final _checkinsSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _aderencia == null;
      _erro = null;
    });
    try {
      final repo = EvolucaoRepository(ref.read(apiClientProvider));
      final consulta = engajamentoPeriodoConsulta(_periodo);
      final dados = await repo.engajamento(
        widget.alunoId,
        dias: consulta.dias,
        inicio: consulta.inicio,
        fim: consulta.fim,
      );
      if (mounted) {
        setState(() {
          _eventos = dados.eventos;
          _aderencia = dados.aderencia;
          _periodoDados = dados.periodo;
          _fichaDesde = dados.fichaDesde;
          _loading = false;
          _fetchedAt = DateTime.now();
        });
        _scrollToInitialSectionIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  void _abrirEvolucao() {
    context.push('/alunos/${widget.alunoId}/evolucao', extra: widget.alunoNome);
  }

  void _abrirChat() {
    context.push('/alunos/${widget.alunoId}/chat', extra: widget.alunoNome);
  }

  void _scrollToInitialSectionIfNeeded() {
    if (widget.initialSection != 'checkins') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _checkinsSectionKey.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.08,
        duration: Duration(milliseconds: fxMotionDurationMs(context)),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _escolherPeriodo() async {
    final escolhido = await showFxInsetPickerSheet<EngajamentoPeriodo>(
      context,
      title: ptS.engajamentoPeriodoTitulo,
      headerIcon: FxIcons.calendario,
      selected: _periodo,
      items: [
        for (final p in EngajamentoPeriodo.values)
          FxInsetPickerSheetItem(value: p, label: engajamentoPeriodoRotulo(p)),
      ],
    );
    if (!mounted || escolhido == null || escolhido == _periodo) return;
    setState(() => _periodo = escolhido);
    await _load();
  }

  /// PDF da aderência do período, com a marca do personal e a trava do plano.
  Future<void> _exportarPdf() async {
    final plano = PlanGate.read(ref, PlanoRecursoKeys.relatorios);
    if (!plano.liberado) {
      await UpgradePromptSheet.show(
        context: context,
        featureName: ptS.engajamentoRelatorioPdf,
        capability: PlanoRecursoKeys.relatorios,
        requiredPlan: plano.planoMinimo,
        upgradePlano: plano.planoMinimo,
        source: 'engajamento_pdf',
      );
      return;
    }
    final p = _periodoDados;
    if (p == null || _exportando) return;
    setState(() => _exportando = true);
    try {
      final inicio = p.inicio;
      final fim = p.fim;
      await exportRelatorioPdf(
        alunoNome: fxTitleCaseName(widget.alunoNome),
        periodoLabel:
            inicio != null && fim != null
                ? relatorioPeriodoLabelPdf(
                  dias: 0,
                  rangeCustom: DateTimeRangePdf(start: inicio, end: fim),
                )
                : engajamentoPeriodoRotulo(_periodo),
        dados: AderenciaData(
          diasAnalisados:
              inicio != null && fim != null
                  ? fim.difference(inicio).inDays + 1
                  : engajamentoPeriodoConsulta(_periodo).dias,
          treinosConcluidos: p.feitos,
          treinosTotal: p.previstos,
          taxaAderenciaPercent: (p.percent ?? 0).toDouble(),
        ),
        comparativo:
            p.percent != null && p.percentAnterior != null
                ? ComparativoPeriodo(
                  aderenciaAtual: p.percent!.toDouble(),
                  aderenciaAnterior: p.percentAnterior!.toDouble(),
                  deltaPercent: (p.diferenca ?? 0).toDouble(),
                  checkInsAtual: p.feitos,
                  checkInsAnterior: 0,
                )
                : null,
        brand: await carregarMarcaDoPdf(ref),
        metas: await ref.read(metasDoAlunoProvider(widget.alunoId).future),
      );
      AnalyticsService.instance.track(
        ProductEvents.relatorioAlunoPdfExported,
        props: {'aluno_id': widget.alunoId, 'origem': 'aderencia'},
      );
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _maisOpcoes() async {
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: ptS.engajamentoMaisOpcoes,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'pdf',
            rotulo: ptS.engajamentoRelatorioPdf,
            descricao: ptS.engajamentoRelatorioApoio,
            icone: FxIcons.pdf,
          ),
          FxActionItem(
            valor: 'evolucao',
            rotulo: ptS.engajamentoVerEvolucao,
            descricao: ptS.engajamentoVerEvolucaoApoio,
            icone: FxIcons.graficoLinha,
          ),
        ]),
      ],
    );
    if (escolha == null || !mounted) return;
    if (escolha == 'evolucao') {
      _abrirEvolucao();
      return;
    }
    await _exportarPdf();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final showSticky = !_loading && _erro == null;
    final conversa = engajamentoConversa(_eventos);
    final freshness = [
      fxTitleCaseName(widget.alunoNome),
      FxHubFreshness.fromFetchedAt(_fetchedAt),
    ].nonNulls.join(' · ');
    return fxScreenA11yScope(
      label: ptS.engajamentoAderencia(widget.alunoNome),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          safePopOrGo(context, '/alunos/${widget.alunoId}');
        },
        child: FxShellScaffold(
          useMesh: true,
          safeArea: false,
          appBar: FxShellAppBar(
            title: ptS.engajamentoAderencia2,
            subtitle: freshness,
            onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
            actions: [
              IconButton(
                tooltip: ptS.engajamentoMaisOpcoes,
                icon: const Icon(FxIcons.mais),
                onPressed: _maisOpcoes,
              ),
              FxHelpIconButton(
                tooltip: ptS.engajamentoComoLerAAderencia,
                onTap: () => showEngajamentoHelpSheet(context),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child:
                    _loading
                        ? const Padding(
                          padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                          child: SkeletonList(count: 6),
                        )
                        : _erro != null
                        ? FxErrorState(
                          chromeOnDark: chrome.isDark,
                          primary: primary,
                          message: _erro!,
                          onRetry: _load,
                          title:
                              ptS.engajamentoNaoConseguimosCarregarAAderencia,
                        )
                        : FxContentWidthLimiter(child: _buildBody()),
              ),
              if (showSticky)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // A última mensagem é o contexto do botão.
                        if (conversa != null) ...[
                          Text(
                            conversa.texto,
                            textAlign: TextAlign.center,
                            style: FocuxHubTypography.bodyMuted(
                              color: chrome.mute,
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s2),
                        ],
                        FxLiquidPrimaryButton(
                          label:
                              conversa?.semResposta == true
                                  ? ptS.engajamentoResponder
                                  : ptS.engajamentoEscrever,
                          onPressed: _abrirChat,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final aluno =
        ref.watch(aluno360OperacaoBundleProvider(widget.alunoId)).value?.aluno;
    final aderencia = aluno?.aderenciaPercent ?? 0;
    final descansos = _aderencia?.diasDescanso ?? const <int>[];
    final diaDaFicha = _aderencia?.diaDaFicha ?? 0;
    final quadroDoPeriodo = engajamentoQuadroDoPeriodo(
      _periodo,
      diaDaFicha: diaDaFicha,
    );
    final semanas = engajamentoSemanas(
      _eventos,
      diasDescanso: descansos,
      diaDaFicha: diaDaFicha,
      semanas: quadroDoPeriodo.semanas,
      ate: quadroDoPeriodo.ate,
    );
    final quadro = engajamentoContagemQuadro(semanas);
    final semanaAtual = engajamentoSemanas(
      _eventos,
      diasDescanso: descansos,
      diaDaFicha: diaDaFicha,
      semanas: 1,
    ).last;
    final naSemana = engajamentoDiasNaSemana(semanaAtual);
    final porSemana = descansos.isEmpty ? null : 7 - descansos.length;
    final periodoRotulo = engajamentoPeriodoRotulo(_periodo);

    final topo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EngajamentoCardAderencia(
          resumo: _aderencia,
          aderenciaCadastro: aderencia,
          frase: engajamentoFrase(_eventos),
          tendencia: engajamentoTendenciaPeriodo(_periodoDados?.diferenca),
          onMontarFicha:
              () => context.push(
                '/alunos/${widget.alunoId}/rotina',
                extra: widget.alunoNome,
              ),
        ),
        if (engajamentoFichaNova(
              _fichaDesde,
              hoje: DateTime.now(),
              diaDaFicha: diaDaFicha,
            )
            case final aviso?) ...[
          const SizedBox(height: TokensStrip.s2),
          Text(
            aviso,
            style: FocuxHubTypography.bodyMuted(color: fxScreenMute(context)),
          ),
        ],
        const SizedBox(height: TokensStrip.s3),
        EngajamentoQuadroSemanas(
          semanas: semanas,
          titulo: periodoRotulo,
          periodo: FxActionChip(
            label: ptS.engajamentoPeriodoTitulo,
            accent: primary,
            isDark: isDark,
            onPressed: _escolherPeriodo,
          ),
          resumo:
              porSemana != null
                  ? ptS.engajamentoFichaPorSemana(porSemana)
                  : quadro.previstos > 0
                  ? ptS.engajamentoResumoQuadro(quadro.feitos, quadro.previstos)
                  : ptS.engajamentoResumoQuadroSemPrevisto(quadro.feitos),
        ),
        const SizedBox(height: TokensStrip.s3),
        KeyedSubtree(
          key: _checkinsSectionKey,
          child: FxMetricStrip(
            metricas: [
              FxMetric(
                valor: _periodoDados?.feitos ?? _aderencia?.feitos ?? 0,
                rotulo: ptS.engajamentoDiasComTreinoEm(periodoRotulo),
              ),
              FxMetric(
                valor: naSemana,
                texto:
                    engajamentoSemanaComecou(semanaAtual)
                        ? ptS.engajamentoSemanaComecou
                        : porSemana == null
                        ? '$naSemana'
                        : ptS.engajamentoDeN(naSemana, porSemana),
                rotulo: ptS.engajamentoEstaSemana,
              ),
              FxMetric(
                valor: aluno?.diasSemTreino ?? 0,
                texto: engajamentoUltimoTreino(aluno?.diasSemTreino),
                rotulo: ptS.engajamentoUltimoTreinoRotulo,
              ),
            ],
          ),
        ),
        if (aluno != null) ...[
          const SizedBox(height: TokensStrip.s4),
          FxTonalButton(
            label: ptS.engajamentoVerHistorico,
            expanded: true,
            onPressed:
                () => showFxHomeSheet<void>(
                  context,
                  builder:
                      (_) => Aluno360TimelineFullSheet(
                        aluno: aluno,
                        isDark: isDark,
                        primary: primary,
                      ),
                ),
          ),
        ],
      ],
    );

    const listBottom = 120.0;
    const padding = EdgeInsets.fromLTRB(
      FxSettingsLayout.pageInset,
      TokensStrip.s4,
      FxSettingsLayout.pageInset,
      listBottom,
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [topo],
      ),
    );
  }
}
