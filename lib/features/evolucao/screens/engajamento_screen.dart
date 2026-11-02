import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fx_metric_strip.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../alunos/providers/aluno_detail_providers.dart';
import '../../planos/data/plano_recurso.dart';
import '../../planos/utils/plan_gate.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../utils/engajamento_display.dart';
import '../widgets/engajamento_card_aderencia.dart';
import '../widgets/engajamento_help_sheet.dart';
import '../widgets/engajamento_quadro_semanas.dart';
import '../../../l10n/pt.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../alunos/widgets/aluno360_timeline_full_sheet.dart';

/// O quadro mostra 5 semanas.
const _diasDoQuadro = 35;

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
  bool _loading = true;
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
      _loading = true;
      _erro = null;
    });
    try {
      final repo = EvolucaoRepository(ref.read(apiClientProvider));
      final eventos = await repo.engajamento(widget.alunoId, dias: _diasDoQuadro);
      if (mounted) {
        setState(() {
          _eventos = eventos.eventos;
          _aderencia = eventos.aderencia;
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

  /// O Relatório tem outra conta e o PDF: mora aqui, com a trava do plano.
  Future<void> _maisOpcoes() async {
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: ptS.engajamentoMaisOpcoes,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'evolucao',
            rotulo: ptS.engajamentoVerEvolucao,
            descricao: ptS.engajamentoVerEvolucaoApoio,
            icone: Icons.show_chart_rounded,
          ),
          FxActionItem(
            valor: 'relatorio',
            rotulo: ptS.engajamentoRelatorioPdf,
            descricao: ptS.engajamentoRelatorioApoio,
            icone: Icons.picture_as_pdf_outlined,
          ),
        ]),
      ],
    );
    if (escolha == null || !mounted) return;
    if (escolha == 'evolucao') {
      _abrirEvolucao();
      return;
    }
    final plano = PlanGate.read(ref, PlanoRecursoKeys.relatorios);
    if (!plano.liberado) {
      await UpgradePromptSheet.show(
        context: context,
        featureName: ptS.engajamentoRelatorioPdf,
        capability: PlanoRecursoKeys.relatorios,
        requiredPlan: plano.planoMinimo,
        upgradePlano: plano.planoMinimo,
        source: 'engajamento_relatorio',
      );
      return;
    }
    context.push(
      '/alunos/${widget.alunoId}/relatorio',
      extra: widget.alunoNome,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = [
      fxTitleCaseName(widget.alunoNome),
      FxHubFreshness.fromFetchedAt(_fetchedAt),
    ].nonNulls.join(' · ');
    final showSticky = !_loading && _erro == null;
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
                icon: const Icon(Icons.more_horiz_rounded),
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
                    child: FxLiquidPrimaryButton(
                      label: ptS.engajamentoEscrever,
                      onPressed: _abrirChat,
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
    final conversa = engajamentoConversa(_eventos);
    final descansos = _aderencia?.diasDescanso ?? const <int>[];
    final semanas = engajamentoSemanas(
      _eventos,
      diasDescanso: descansos,
      diaDaFicha: _aderencia?.diaDaFicha ?? 0,
    );
    final quadro = engajamentoContagemQuadro(semanas);
    final naSemana = engajamentoDiasNaSemana(semanas.last);

    final topo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EngajamentoCardAderencia(
          resumo: _aderencia,
          aderenciaCadastro: aderencia,
          frase: engajamentoFrase(_eventos),
          tendencia: engajamentoTendencia(_eventos),
          onMontarFicha:
              () => context.push(
                '/alunos/${widget.alunoId}/rotina',
                extra: widget.alunoNome,
              ),
        ),
        const SizedBox(height: TokensStrip.s3),
        EngajamentoQuadroSemanas(
          semanas: semanas,
          resumo:
              quadro.previstos > 0
                  ? ptS.engajamentoResumoQuadro(quadro.feitos, quadro.previstos)
                  : ptS.engajamentoResumoQuadroSemPrevisto(quadro.feitos),
        ),
        const SizedBox(height: TokensStrip.s3),
        KeyedSubtree(
          key: _checkinsSectionKey,
          child: FxMetricStrip(
            metricas: [
              FxMetric(
                valor: _aderencia?.feitos ?? engajamentoTreinosSemana(_eventos),
                rotulo: ptS.engajamentoDiasComTreino,
              ),
              FxMetric(
                valor: naSemana,
                texto:
                    descansos.isEmpty
                        ? '$naSemana'
                        : ptS.engajamentoDeN(naSemana, 7 - descansos.length),
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
        if (conversa != null) ...[
          const SizedBox(height: TokensStrip.s3),
          Row(
            children: [
              Expanded(
                child: Text(
                  conversa.texto,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
              ),
              if (conversa.semResposta)
                FxTonalButton(
                  label: ptS.engajamentoResponder,
                  compact: true,
                  onPressed: _abrirChat,
                ),
            ],
          ),
        ],
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

    const listBottom = 88.0;
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
