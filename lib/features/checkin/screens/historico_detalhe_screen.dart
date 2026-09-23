import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../data/checkin_repository.dart';
import '../data/historico_mem_cache.dart';
import '../providers/checkin_provider.dart';
import '../utils/checkin_execucao_display.dart';
import '../utils/historico_display.dart';
import '../utils/historico_sessao_metrics.dart';

class HistoricoDetalheScreen extends ConsumerStatefulWidget {
  const HistoricoDetalheScreen({super.key, required this.execucaoId});

  final int execucaoId;

  @override
  ConsumerState<HistoricoDetalheScreen> createState() =>
      _HistoricoDetalheScreenState();
}

class _HistoricoDetalheScreenState
    extends ConsumerState<HistoricoDetalheScreen> {
  ExecucaoTreino? _execucao;
  HistoricoSessaoMetrics? _evolucao;
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  var _secao = historicoSecaoExercicios;

  @override
  void initState() {
    super.initState();
    final cached = HistoricoDetalheMemCache.loadIfFresh(widget.execucaoId);
    if (cached != null) {
      _execucao = cached;
      _evolucao = historicoSessaoMetricsFromExecucao(cached);
      _loading = false;
      _fetchedAt = DateTime.now();
    }
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = _execucao == null;
      _erro = null;
    });
    try {
      final repo = ref.read(checkinRepositoryProvider);
      final loaded = await repo.detalhe(widget.execucaoId);
      if (!mounted) return;
      final local = historicoSessaoMetricsFromExecucao(loaded);
      setState(() {
        _execucao = loaded;
        _evolucao = local;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
      HistoricoDetalheMemCache.save(loaded);
      // Onda B em paralelo — não bloqueia first paint.
      unawaited(_carregarEvolucao(repo));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _carregarEvolucao(CheckinRepository repo) async {
    try {
      final dto = await repo.evolucaoSessao(widget.execucaoId);
      if (!mounted) return;
      setState(() => _evolucao = historicoSessaoMetricsFromDto(dto));
    } catch (_) {
      // Mantém métricas locais (Onda A).
    }
  }

  void _leave() => safePopOrGo(context, '/checkin/historico');

  void _agir() {
    final execucao = _execucao;
    if (execucao == null) return;
    context.push('/checkin/executar', extra: execucao.treinoId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final execucao = _execucao;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: execucao?.treinoNome ?? 'Treino',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _leave();
        },
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: execucao?.treinoNome ?? 'Treino',
            subtitle:
                execucao != null &&
                        historicoDateLabel(execucao.iniciadoEm).isNotEmpty
                    ? historicoDateLabel(execucao.iniciadoEm)
                    : freshness,
            onBack: _leave,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como ler esta sessão',
                onTap: () => showFxHelpSheet(
                  context,
                  title: 'Sessão do histórico',
                  subtitle: 'O que aconteceu neste treino e o próximo passo.',
                  tips: const [
                    FxHelpTip(
                      'Continuar',
                      'Se ficou pela metade, o botão retoma a execução.',
                      icon: 'circle-check',
                    ),
                    FxHelpTip(
                      'De novo',
                      'Sessão concluída abre um treino novo com o mesmo plano.',
                      icon: 'dumbbell',
                    ),
                  ],
                ),
              ),
            ],
          ),
          body:
              _loading && execucao == null
                  ? Padding(
                    padding: const EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: FxLoading.sectionShimmer(
                      context,
                      height: 220,
                    ),
                  )
                  : _erro != null && execucao == null
                  ? FxContentWidthLimiter(
                    child: FxErrorState(
                      chromeOnDark: isDark,
                      primary: primary,
                      title: FocuxMicrocopy.naoFoiPossivelCarregar,
                      message: _erro!,
                      onRetry: _carregar,
                    ),
                  )
                  : execucao == null
                  ? FxContentWidthLimiter(
                    child: FxEmptyState(
                      icon: 'dumbbell',
                      title: 'Treino não encontrado',
                      subtitle: 'Volte ao histórico e escolha outro.',
                      action: FxEmptyAction(label: 'Voltar', onTap: _leave),
                    ),
                  )
                  : _DetalheBody(
                    execucao: execucao,
                    metrics:
                        _evolucao ?? historicoSessaoMetricsFromExecucao(execucao),
                    secao: _secao,
                    onSecao: (value) => setState(() => _secao = value),
                    onRefresh: _carregar,
                    onAct: _agir,
                    onLeave: _leave,
                  ),
        ),
      ),
    );
  }
}

class _DetalheBody extends StatelessWidget {
  const _DetalheBody({
    required this.execucao,
    required this.metrics,
    required this.secao,
    required this.onSecao,
    required this.onRefresh,
    required this.onAct,
    required this.onLeave,
  });

  final ExecucaoTreino execucao;
  final HistoricoSessaoMetrics metrics;
  final String secao;
  final ValueChanged<String> onSecao;
  final Future<void> Function() onRefresh;
  final VoidCallback onAct;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final done = historicoExerciciosConcluidos(
      execucao.exercicios.map((item) {
        final feitas = historicoSeriesFeitasEfetivas(
          seriesFeitas: item.seriesFeitas,
          seriesDetalhesCount: item.seriesDetalhes.length,
        );
        return historicoExercicioConcluidoEfetivo(
          concluido: item.concluido,
          seriesFeitas: feitas,
          series: item.series,
        );
      }),
    );
    final total = execucao.exercicios.length;
    final concluido = historicoConcluido(execucao.status);
    final duracao = historicoDuracaoLabel(
      execucao.iniciadoEm,
      execucao.concluidoEm,
      sessaoAberta: !concluido,
    );
    final prs = execucao.evolucoesPerformance;
    final cargas = execucao.evolucoesCarga;
    final recordes = metrics.recordes > 0
        ? metrics.recordes
        : historicoRecordesCount(prs: prs.length, cargas: cargas.length);
    final emptySeries = historicoEmptySeriesFromExercicios(execucao.exercicios);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: primary,
            onRefresh: onRefresh,
            child: FxContentWidthLimiter(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s5,
                ),
                children: [
                  FxStripCard(
                    emphasize: false,
                    accent: primary,
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s3,
                      TokensStrip.s3,
                      TokensStrip.s3,
                      TokensStrip.s2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sinal',
                          style: FocuxHubTypography.chip(fxScreenMute(context)),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                historicoStatusDisplayLabel(
                                  status: execucao.status,
                                  seriesFeitas: metrics.seriesFeitas,
                                ),
                                style: FocuxHubTypography.kpi(
                                  color: fxScreenInk(context),
                                  fontSize: FocuxHubTypography.metricMd,
                                ),
                              ),
                            ),
                            const SizedBox(width: TokensStrip.s2),
                            Text(
                              duracao ?? '—',
                              style: FocuxHubTypography.kpi(
                                color: primary,
                                fontSize: FocuxHubTypography.metricEm,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TokensStrip.s1),
                        Text(
                          metrics.sinalLabel,
                          style: FocuxHubTypography.bodyMuted(
                            color: fxScreenMute(context),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        Row(
                          children: [
                            Expanded(
                              child: OperationalMetricTile(
                                label: 'Volume',
                                value: metrics.volumeLabel,
                                hint: metrics.volumeAnteriorKg != null
                                    ? 'antes ${historicoVolumeLabel(metrics.volumeAnteriorKg!)}'
                                    : (metrics.volumeKg == null
                                        ? 'sem cargas'
                                        : 'nesta sessão'),
                                color: primary,
                                isDark: isDark,
                                dense: true,
                                emphasis: OperationalMetricEmphasis.muted,
                              ),
                            ),
                            const SizedBox(width: TokensStrip.s2),
                            Expanded(
                              child: OperationalMetricTile(
                                label: 'Séries',
                                value: metrics.seriesLabel,
                                hint: metrics.seriesHint,
                                color: primary,
                                isDark: isDark,
                                dense: true,
                                emphasis: OperationalMetricEmphasis.muted,
                              ),
                            ),
                            const SizedBox(width: TokensStrip.s2),
                            Expanded(
                              child: OperationalMetricTile(
                                label: recordes > 0 ? 'Recordes' : 'Exerc.',
                                value: recordes > 0
                                    ? '$recordes'
                                    : '$done/$total',
                                hint: recordes > 0
                                    ? historicoPrHint(recordes)
                                    : historicoExerciciosMetricHint(total),
                                color: primary,
                                isDark: isDark,
                                dense: true,
                                emphasis: OperationalMetricEmphasis.muted,
                              ),
                            ),
                          ],
                        ),
                        if (metrics.destaqueExercicio != null &&
                            metrics.destaqueDeltaKg != null) ...[
                          const SizedBox(height: TokensStrip.s2),
                          Text(
                            '${metrics.destaqueExercicio}: '
                            '${historicoDeltaKgLabel(metrics.destaqueDeltaKg!)}',
                            style: FocuxHubTypography.chip(primary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  AlunoSegmentedChoice(
                    options: historicoDetalheSecoes,
                    selected: secao,
                    isDark: isDark,
                    onSelect: onSecao,
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  if (secao == historicoSecaoRecordes)
                    ..._recordes(prs, cargas)
                  else if (secao == historicoSecaoNotas)
                    ..._notas(execucao.exercicios)
                  else if (execucao.exercicios.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: TokensStrip.s1),
                      child: Text(
                        'Sem exercícios nesta execução.',
                        style: FocuxHubTypography.bodyMuted(
                          color: fxScreenMute(context),
                        ),
                      ),
                    )
                  else ...[
                    if (emptySeries >= 3)
                      Padding(
                        padding: const EdgeInsets.only(bottom: TokensStrip.s2),
                        child: Text(
                          historicoEmptySeriesSummary(emptySeries),
                          style: FocuxHubTypography.bodyMuted(
                            color: fxScreenMute(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    for (final item in execucao.exercicios)
                      Builder(
                        builder: (context) {
                          final feitas = historicoSeriesFeitasEfetivas(
                            seriesFeitas: item.seriesFeitas,
                            seriesDetalhesCount: item.seriesDetalhes.length,
                          );
                          final feito = historicoExercicioConcluidoEfetivo(
                            concluido: item.concluido,
                            seriesFeitas: feitas,
                            series: item.series,
                          );
                          final carga = _carga(item);
                          final delta = historicoCargaDeltaLabel(
                            cargaAtual: item.seriesDetalhes.isNotEmpty
                                ? item.seriesDetalhes.last.cargaKg
                                : item.cargaKg,
                            cargaAnterior: item.cargaAnteriorKg,
                          );
                          final spark = historicoCargaSparkValues(
                            item.seriesDetalhes,
                          );
                          final subtitle = [
                            historicoExercicioSubtitle(
                              seriesFeitas: feitas,
                              series: item.series,
                              concluido: feito,
                              sessaoConcluida: concluido,
                              carga: carga,
                              rpe: _rpe(item),
                              dor: item.dor ||
                                  item.seriesDetalhes.any((s) => s.dor),
                            ),
                            if (delta != null) delta,
                          ].join(' · ');
                          return FxSatelliteListTile(
                            title: item.exercicioNome,
                            margin: const EdgeInsets.only(bottom: 2),
                            subtitle: Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: FxIcon(
                              name: feito ? 'circle-check' : 'target',
                              size: 18,
                              color:
                                  feito
                                      ? EagleTokens.good
                                      : EagleTokens.warn,
                            ),
                            accent: feito ? null : EagleTokens.warn,
                            trailing: spark.length >= 2
                                ? FxSparkline(
                                  data: spark,
                                  color: primary,
                                  width: 44,
                                  height: 18,
                                  strokeWidth: 1.5,
                                )
                                : null,
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              TokensStrip.s1,
              FxSettingsLayout.pageInset,
              TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: FxLiquidPrimaryButton(
              label: historicoStickyLabel(execucao.status),
              onPressed: onAct,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _notas(List<ExecucaoExercicio> exercicios) {
    final tiles = <Widget>[
      for (final item in exercicios)
        if (historicoNotaLine(
              observacoes: item.observacoes,
              feedback: item.feedback,
            )
            case final nota?)
          FxSatelliteListTile(
            title: item.exercicioNome,
            margin: const EdgeInsets.only(bottom: 2),
            subtitle: Text(nota),
            leading: const FxIcon(
              name: 'article',
              size: 20,
              color: EagleTokens.good,
            ),
          ),
    ];
    if (tiles.isEmpty) {
      return [
        const FxEmptyState(
          icon: 'article',
          title: 'Nenhuma nota nesta sessão',
          subtitle: 'Observação e feedback do exercício aparecem aqui.',
          quiet: true,
        ),
      ];
    }
    return tiles;
  }

  List<Widget> _recordes(
    List<EvolucaoPerformance> prs,
    List<EvolucaoCarga> cargas,
  ) {
    if (prs.isEmpty && cargas.isEmpty) {
      return [
        const FxEmptyState(
          icon: 'star',
          title: 'Nenhum recorde nesta sessão',
          subtitle: 'Quando bater carga ou volume, o recorde aparece aqui.',
          quiet: true,
        ),
      ];
    }
    return [
      for (final carga in cargas)
        FxSatelliteListTile(
          title: carga.exercicioNome,
          margin: const EdgeInsets.only(bottom: 2),
          subtitle: Text(
            carga.mensagem.trim().isEmpty
                ? (checkinCargaLabel(carga.cargaAtualKg) ?? historicoPrHint(1))
                : carga.mensagem.trim(),
          ),
          leading: const FxIcon(
            name: 'dumbbell',
            size: 20,
            color: EagleTokens.good,
          ),
        ),
      for (final pr in prs)
        FxSatelliteListTile(
          title: pr.exercicioNome,
          margin: const EdgeInsets.only(bottom: 2),
          subtitle: Text(
            pr.mensagem.trim().isEmpty
                ? historicoPrHint(1)
                : pr.mensagem.trim(),
          ),
          leading: const FxIcon(
            name: 'star',
            size: 20,
            color: EagleTokens.good,
          ),
        ),
    ];
  }

  String? _carga(ExecucaoExercicio item) {
    final fromItem = checkinCargaLabel(item.cargaKg);
    if (fromItem != null) return fromItem;
    if (item.seriesDetalhes.isEmpty) return null;
    return checkinCargaLabel(item.seriesDetalhes.last.cargaKg);
  }

  int? _rpe(ExecucaoExercicio item) {
    if (item.rpe != null) return item.rpe;
    if (item.seriesDetalhes.isEmpty) return null;
    return item.seriesDetalhes.last.rpe;
  }
}
