import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';
import '../utils/checkin_execucao_display.dart';
import '../utils/historico_display.dart';

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
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  var _secao = historicoSecaoExercicios;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final loaded = await ref
          .read(checkinRepositoryProvider)
          .detalhe(widget.execucaoId);
      if (!mounted) return;
      setState(() {
        _execucao = loaded;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
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
          appBar: FxShellAppBar(
            title: 'Treino',
            subtitle: freshness,
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
                  ? const Padding(
                    padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: SkeletonList(count: 4),
                  )
                  : _erro != null && execucao == null
                  ? FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    title: FocuxMicrocopy.naoFoiPossivelCarregar,
                    message: _erro!,
                    onRetry: _carregar,
                  )
                  : execucao == null
                  ? FxEmptyState(
                    icon: 'dumbbell',
                    title: 'Treino não encontrado',
                    subtitle: 'Volte ao histórico e escolha outro.',
                    action: FxEmptyAction(label: 'Voltar', onTap: _leave),
                  )
                  : _DetalheBody(
                    execucao: execucao,
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
    required this.secao,
    required this.onSecao,
    required this.onRefresh,
    required this.onAct,
    required this.onLeave,
  });

  final ExecucaoTreino execucao;
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
      execucao.exercicios.map((item) => item.concluido),
    );
    final total = execucao.exercicios.length;
    final concluido = historicoConcluido(execucao.status);
    final duracao = historicoDuracaoLabel(
      execucao.iniciadoEm,
      execucao.concluidoEm,
    );
    final prs = execucao.evolucoesPerformance;
    final cargas = execucao.evolucoesCarga;
    final recordes = historicoRecordesCount(prs: prs.length, cargas: cargas.length);

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
                  TokensStrip.s4,
                  FxSettingsLayout.pageInset,
                  24,
                ),
                children: [
                  FxHubHeader(
                    title: execucao.treinoNome,
                    subtitle: historicoDetalheSubtitle(
                      status: execucao.status,
                      iniciadoEm: execucao.iniciadoEm,
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  OperationalMetricTile(
                    label: 'Exercícios',
                    value: historicoExerciciosMetric(done: done, total: total),
                    hint: historicoCountLabel(total),
                    color: primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  OperationalMetricTile(
                    label: 'Status',
                    value: historicoStatusLabel(execucao.status),
                    hint: historicoDateLabel(execucao.iniciadoEm).isEmpty
                        ? 'Nesta sessão'
                        : historicoDateLabel(execucao.iniciadoEm),
                    color: concluido ? EagleTokens.good : EagleTokens.warn,
                    isDark: isDark,
                    emphasis:
                        concluido
                            ? OperationalMetricEmphasis.normal
                            : OperationalMetricEmphasis.alert,
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  OperationalMetricTile(
                    label: 'Duração',
                    value: duracao ?? '—',
                    hint: concluido ? 'Sessão fechada' : 'Em andamento',
                    color: primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  OperationalMetricTile(
                    label: 'Recordes',
                    value: historicoPrMetric(recordes),
                    hint: historicoPrHint(recordes),
                    color: primary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: TokensStrip.s3),
                  Wrap(
                    spacing: TokensStrip.s2,
                    runSpacing: TokensStrip.s2,
                    children: [
                      DashboardHomeActionChip(
                        label: 'Histórico',
                        accent: primary,
                        isDark: isDark,
                        onPressed: onLeave,
                      ),
                      DashboardHomeActionChip(
                        label: 'Treinos',
                        accent: primary,
                        isDark: isDark,
                        onPressed: () => context.push('/checkin/treinos'),
                      ),
                      DashboardHomeActionChip(
                        label: 'Hoje',
                        accent: primary,
                        isDark: isDark,
                        onPressed: () => context.push('/dashboard/aluno'),
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  AlunoSegmentedChoice(
                    options: historicoDetalheSecoes,
                    selected: secao,
                    isDark: isDark,
                    onSelect: onSecao,
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  if (secao == historicoSecaoRecordes)
                    ..._recordes(prs, cargas)
                  else if (secao == historicoSecaoNotas)
                    ..._notas(execucao.exercicios)
                  else if (execucao.exercicios.isEmpty)
                    const FxEmptyState(
                      icon: 'dumbbell',
                      title: 'Sem exercícios nesta execução',
                      subtitle: 'O treino ainda pode ser feito de novo.',
                    )
                  else
                    for (final item in execucao.exercicios)
                      FxSatelliteListTile(
                        title: item.exercicioNome,
                        subtitle: Text(
                          historicoExercicioSubtitle(
                            seriesFeitas: item.seriesFeitas,
                            series: item.series,
                            concluido: item.concluido,
                            carga: _carga(item),
                            rpe: _rpe(item),
                            dor: item.dor ||
                                item.seriesDetalhes.any((serie) => serie.dor),
                          ),
                        ),
                        leading: FxIcon(
                          name: item.concluido ? 'circle-check' : 'calendar',
                          size: 22,
                          color:
                              item.concluido
                                  ? EagleTokens.good
                                  : EagleTokens.warn,
                        ),
                        accent: item.concluido ? null : EagleTokens.warn,
                      ),
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
              TokensStrip.s2,
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
            subtitle: Text(nota),
            leading: const FxIcon(
              name: 'article',
              size: 22,
              color: EagleTokens.good,
            ),
          ),
    ];
    if (tiles.isEmpty) {
      return [
        FxEmptyState(
          icon: 'article',
          title: historicoNotasEmpty(),
          subtitle: 'Observação e feedback do exercício aparecem aqui.',
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
        FxEmptyState(
          icon: 'star',
          title: historicoRecordesEmpty(),
          subtitle: 'Quando bater carga ou volume, o recorde aparece aqui.',
        ),
      ];
    }
    return [
      for (final carga in cargas)
        FxSatelliteListTile(
          title: carga.exercicioNome,
          subtitle: Text(
            carga.mensagem.trim().isEmpty
                ? (checkinCargaLabel(carga.cargaAtualKg) ?? historicoPrHint(1))
                : carga.mensagem.trim(),
          ),
          leading: const FxIcon(
            name: 'dumbbell',
            size: 22,
            color: EagleTokens.good,
          ),
        ),
      for (final pr in prs)
        FxSatelliteListTile(
          title: pr.exercicioNome,
          subtitle: Text(
            pr.mensagem.trim().isEmpty
                ? historicoPrHint(1)
                : pr.mensagem.trim(),
          ),
          leading: const FxIcon(
            name: 'star',
            size: 22,
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
