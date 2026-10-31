import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_metric_strip.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../alunos/providers/aluno_detail_providers.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../utils/engajamento_display.dart';
import '../widgets/engajamento_card_aderencia.dart';
import '../widgets/engajamento_help_sheet.dart';
import '../../../l10n/pt.dart';

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
  int _dias = 30;
  List<EventoEngajamento> _eventos = [];
  AderenciaResumo? _aderencia;
  bool _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  final _checkinsSectionKey = GlobalKey();
  var _filtro = EngajamentoFiltro.tudo;
  var _mostrarCancelados = false;

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
      final eventos = await repo.engajamento(widget.alunoId, dias: _dias);
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

  Future<void> _pickPeriodo() async {
    HapticFeedback.selectionClick();
    final picked = await showFxInsetPickerSheet<int>(
      context,
      title: ptS.engajamentoPeriodo,
      selected: _dias,
      items: [
        for (final d in engajamentoPeriodos)
          FxInsetPickerSheetItem(value: d, label: engajamentoPeriodoLabel(d)),
      ],
    );
    if (!mounted || picked == null || picked == _dias) return;
    setState(() => _dias = picked);
    await _load();
  }

  void _verNoventaDias() {
    if (_dias == 90) return;
    setState(() => _dias = 90);
    _load();
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

  void _abrirEvento(EventoEngajamento evento) {
    final rota = engajamentoEventoRota(evento.tipo, widget.alunoId);
    if (rota == null) return;
    context.push(rota, extra: widget.alunoNome);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
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
    final cancelados = engajamentoCanceladosCount(_eventos);
    final linhas = engajamentoLinhasPorDia(
      engajamentoAtividade(
        _eventos,
        filtro: _filtro,
        mostrarCancelados: _mostrarCancelados,
      ),
    );

    final dias = <(String, List<EventoEngajamento>)>[];
    for (final linha in linhas) {
      final evento = linha.evento;
      if (evento == null) {
        dias.add((linha.dia!, []));
      } else {
        if (dias.isEmpty) dias.add(('', []));
        dias.last.$2.add(evento);
      }
    }

    final topo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxHubHeader(
          title: fxTitleCaseName(widget.alunoNome),
          subtitle: engajamentoPeriodoLabel(_dias),
        ),
        const SizedBox(height: TokensStrip.s4),
        EngajamentoCardAderencia(
          resumo: _aderencia,
          aderenciaCadastro: aderencia,
          frase: engajamentoFrase(_eventos),
          tendencia: engajamentoTendencia(_eventos),
        ),
        const SizedBox(height: TokensStrip.s3),
        KeyedSubtree(
          key: _checkinsSectionKey,
          child: FxMetricStrip(
            metricas: [
              FxMetric(
                valor: engajamentoTreinosCount(_eventos),
                rotulo: ptS.engajamentoTreinosFeitos,
              ),
              FxMetric(
                valor: aluno?.diasSemTreino ?? 0,
                rotulo: ptS.alunoResumoMetricaDiasSemTreino,
              ),
              FxMetric(
                valor: engajamentoTreinosSemana(_eventos),
                rotulo: ptS.alunoResumoMetricaCheckins,
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensStrip.s3),
        _CalendarioTreinos(
          dias: engajamentoCalendario(_eventos),
          diasDescanso: _aderencia?.diasDescanso ?? const [],
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
        const SizedBox(height: TokensStrip.s4),
        Wrap(
          spacing: TokensStrip.s2,
          runSpacing: TokensStrip.s2,
          children: [
            FxActionChip(
              label: engajamentoPeriodoLabel(_dias),
              accent: primary,
              isDark: isDark,
              onPressed: _pickPeriodo,
            ),
            FxActionChip(
              label: ptS.alunoEvolucaoTitulo,
              accent: primary,
              isDark: isDark,
              onPressed: _abrirEvolucao,
            ),
          ],
        ),
        const SizedBox(height: TokensStrip.s3),
        FxChoiceStrip<EngajamentoFiltro>(
          itens: [
            for (final filtro in EngajamentoFiltro.values)
              FxChoiceItem(
                value: filtro,
                label: engajamentoFiltroLabel(filtro),
              ),
          ],
          selecionado: _filtro,
          onSelecionar: (filtro) => setState(() => _filtro = filtro),
        ),
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
      child:
          _eventos.isEmpty
              ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: padding,
                children: [
                  topo,
                  const SizedBox(height: TokensStrip.s5),
                  FxEmptyState(
                    icon: 'trend',
                    title: ptS.engajamentoNadaNestePeriodo,
                    subtitle: ptS.engajamentoTreinosMedidasEMensagensDo,
                    action:
                        _dias == 90
                            ? null
                            : FxEmptyAction(
                              label: ptS.engajamentoVer90Dias,
                              onTap: _verNoventaDias,
                            ),
                  ),
                ],
              )
              : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: padding,
                itemCount: dias.length + 2,
                itemBuilder: (context, i) {
                  if (i == 0) return topo;
                  if (i == dias.length + 1) {
                    if (cancelados == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: TokensStrip.s3),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FxActionLink(
                          label:
                              _mostrarCancelados
                                  ? ptS.engajamentoEsconderCanceladas
                                  : ptS.engajamentoMostrarCanceladas(
                                    cancelados,
                                  ),
                          onTap:
                              () => setState(
                                () => _mostrarCancelados = !_mostrarCancelados,
                              ),
                        ),
                      ),
                    );
                  }
                  final (dia, eventos) = dias[i - 1];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (dia.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: TokensStrip.s5,
                            bottom: TokensStrip.s3,
                          ),
                          child: DashboardSectionHeader(title: dia),
                        ),
                      Container(
                        decoration: fxListCardDecoration(context),
                        child: Column(
                          children: [
                            for (final (j, evento) in eventos.indexed) ...[
                              if (j > 0) const Divider(height: 1),
                              _LinhaAtividade(
                                evento: evento,
                                onTap:
                                    engajamentoEventoRota(
                                              evento.tipo,
                                              widget.alunoId,
                                            ) ==
                                            null
                                        ? null
                                        : () => _abrirEvento(evento),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }
}

/// Uma linha do cartão de Atividade: ícone, o que houve e a hora.
class _LinhaAtividade extends StatelessWidget {
  const _LinhaAtividade({required this.evento, required this.onTap});

  final EventoEngajamento evento;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final titulo = engajamentoEventoLabel(evento.descricao, evento.tipo);
    final apoio = engajamentoEventoSubtitle(tipo: evento.tipo, titulo: titulo);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TokensStrip.s3,
            vertical: TokensStrip.s2,
          ),
          child: Row(
            children: [
              FxIcon(
                name: engajamentoFxIcon(evento.tipo),
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: TokensStrip.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.cardTitle(color: chrome.ink),
                    ),
                    if (apoio != null)
                      Text(
                        apoio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: TokensStrip.s2),
              Text(
                engajamentoHoraLabel(evento.dataHora),
                style: FocuxHubTypography.bodyMuted(
                  color: chrome.mute,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cinco semanas, um ponto por dia. Hoje é o último ponto.
class _CalendarioTreinos extends StatelessWidget {
  const _CalendarioTreinos({required this.dias, required this.diasDescanso});

  final List<({DateTime dia, EngajamentoTreinoEstado? estado})> dias;

  /// Fora daqui, dia sem treino é falta: aparece em contorno.
  final List<int> diasDescanso;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final feitos =
        dias.where((d) => d.estado == EngajamentoTreinoEstado.feito).length;
    final cor = chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn;
    final parcial = primary.withValues(alpha: 0.4);

    Widget ponto(Color fundo) => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: fundo, shape: BoxShape.circle),
    );
    Widget legenda(Color fundo, String texto) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ponto(fundo),
        const SizedBox(width: TokensStrip.s1),
        Text(texto, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
      ],
    );

    return Semantics(
      label: ptS.engajamentoUltimas5SemanasDiasCom(feitos),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s3),
        decoration: fxListCardDecoration(context),
        child: Column(
          children: [
            for (var semana = 0; semana < dias.length ~/ 7; semana++) ...[
              if (semana > 0) const SizedBox(height: TokensStrip.s2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final d in dias.skip(semana * 7).take(7))
                    d.estado == null &&
                            diasDescanso.isNotEmpty &&
                            !diasDescanso.contains(d.dia.weekday)
                        ? Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: chrome.lineStrong),
                          ),
                        )
                        : ponto(switch (d.estado) {
                          EngajamentoTreinoEstado.feito => primary,
                          EngajamentoTreinoEstado.parcial => parcial,
                          EngajamentoTreinoEstado.cancelado => cor,
                          _ => chrome.line,
                        }),
                ],
              ),
            ],
            const SizedBox(height: TokensStrip.s3),
            Row(
              children: [
                legenda(primary, ptS.engajamentoTreinou),
                const SizedBox(width: TokensStrip.s3),
                legenda(parcial, ptS.historicoParcial),
                const SizedBox(width: TokensStrip.s3),
                legenda(cor, ptS.engajamentoCancelou),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
