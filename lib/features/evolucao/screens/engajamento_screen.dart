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
import '../../../core/widgets/fx_status_pill.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../alunos/providers/aluno_detail_providers.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../utils/engajamento_display.dart';
import '../widgets/engajamento_help_sheet.dart';

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
          _eventos = eventos;
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
      title: 'Período',
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
    context.push(
      '/alunos/${widget.alunoId}/evolucao',
      extra: widget.alunoNome,
    );
  }

  void _abrirChat() {
    context.push(
      '/alunos/${widget.alunoId}/chat',
      extra: widget.alunoNome,
    );
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
      label: 'Aderência — ${widget.alunoNome}',
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
          title: 'Aderência',
          subtitle: freshness,
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como ler a aderência',
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
                        title: 'Não conseguimos carregar a aderência',
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
                    label: 'Escrever',
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
    final aluno = ref.watch(aluno360OperacaoBundleProvider(widget.alunoId)).value?.aluno;
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

    final topo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxHubHeader(
          title: fxTitleCaseName(widget.alunoNome),
          subtitle: engajamentoPeriodoLabel(_dias),
        ),
        const SizedBox(height: TokensStrip.s4),
        FxStripCard(
          emphasize: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aderência em 30 dias',
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              const SizedBox(height: TokensStrip.s1),
              Text(
                aderencia > 0 ? '$aderencia%' : 'Sem treinos ainda',
                style: FocuxHubTypography.metric(
                  color: chrome.ink,
                  fontSize:
                      aderencia > 0
                          ? FocuxHubTypography.metricLg
                          : FocuxHubTypography.metricMd,
                ),
              ),
              const SizedBox(height: TokensStrip.s2),
              Text(
                engajamentoFrase(_eventos),
                style: FocuxHubTypography.body(color: chrome.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensStrip.s3),
        KeyedSubtree(
          key: _checkinsSectionKey,
          child: FxMetricStrip(
            metricas: [
              FxMetric(
                valor: engajamentoTreinosCount(_eventos),
                rotulo: 'Treinos feitos',
              ),
              FxMetric(
                valor: aluno?.diasSemTreino ?? 0,
                rotulo: 'Dias sem treino',
              ),
              FxMetric(
                valor: engajamentoTreinosSemana(_eventos),
                rotulo: 'Sessões 7 dias',
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensStrip.s3),
        _CalendarioTreinos(dias: engajamentoCalendario(_eventos)),
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
                const FxStatusPill(
                  label: 'Sem resposta sua',
                  tone: FxPillTone.warning,
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
              label: 'Evolução',
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
      child: _eventos.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding,
              children: [
                topo,
                const SizedBox(height: TokensStrip.s5),
                FxEmptyState(
                  icon: 'trend',
                  title: 'Nada neste período',
                  subtitle:
                      'Treinos, medidas e mensagens do aluno aparecem aqui.',
                  action:
                      _dias == 90
                          ? null
                          : FxEmptyAction(
                            label: 'Ver 90 dias',
                            onTap: _verNoventaDias,
                          ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding,
              itemCount: linhas.length + 2,
              itemBuilder: (context, i) {
                if (i == 0) return topo;
                if (i == linhas.length + 1) {
                  if (cancelados == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: TokensStrip.s3),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FxActionLink(
                        label:
                            _mostrarCancelados
                                ? 'Esconder canceladas'
                                : 'Mostrar canceladas ($cancelados)',
                        onTap:
                            () => setState(
                              () => _mostrarCancelados = !_mostrarCancelados,
                            ),
                      ),
                    ),
                  );
                }
                final linha = linhas[i - 1];
                final evento = linha.evento;
                if (evento == null) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: TokensStrip.s5,
                      bottom: TokensStrip.s3,
                    ),
                    child: DashboardSectionHeader(title: linha.dia!),
                  );
                }
                final titulo = engajamentoEventoLabel(
                  evento.descricao,
                  evento.tipo,
                );
                final apoio = engajamentoEventoSubtitle(
                  tipo: evento.tipo,
                  titulo: titulo,
                );
                return FxSatelliteListTile(
                  title: titulo,
                  titleCase: false,
                  onTap:
                      engajamentoEventoRota(evento.tipo, widget.alunoId) ==
                              null
                          ? null
                          : () => _abrirEvento(evento),
                  subtitle: apoio == null ? null : Text(apoio),
                  leading: FxIcon(
                    name: engajamentoFxIcon(evento.tipo),
                    size: 18,
                    color: primary,
                  ),
                  trailing: Text(
                    engajamentoHoraLabel(evento.dataHora),
                    style: FocuxHubTypography.bodyMuted(
                      color: fxScreenMute(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Cinco semanas, um ponto por dia. Hoje é o último ponto.
class _CalendarioTreinos extends StatelessWidget {
  const _CalendarioTreinos({required this.dias});

  final List<({DateTime dia, EngajamentoTreinoEstado? estado})> dias;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final feitos =
        dias.where((d) => d.estado == EngajamentoTreinoEstado.feito).length;
    final cor = chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn;

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
      label: 'Últimas 5 semanas: $feitos dias com treino',
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
                    ponto(switch (d.estado) {
                      EngajamentoTreinoEstado.feito => primary,
                      EngajamentoTreinoEstado.cancelado => cor,
                      _ => chrome.line,
                    }),
                ],
              ),
            ],
            const SizedBox(height: TokensStrip.s3),
            Row(
              children: [
                legenda(primary, 'Treinou'),
                const SizedBox(width: TokensStrip.s3),
                legenda(cor, 'Cancelou'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
