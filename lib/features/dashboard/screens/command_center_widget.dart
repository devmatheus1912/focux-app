import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../data/command_center_data.dart';
import '../providers/dashboard_provider.dart';

class CommandCenterWidget extends ConsumerWidget {
  const CommandCenterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandCenterAsync = ref.watch(commandCenterProvider);

    return commandCenterAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: ShimmerListLoading(itemCount: 4, itemHeight: 72),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              friendlyError(
                e,
                fallback: 'Não foi possível carregar a Central de Comando.',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ref.invalidate(commandCenterProvider),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (data) {
        if (data.agendaHoje.isEmpty &&
            data.filaAcoes.isEmpty &&
            data.alunosScore.isEmpty &&
            data.autonomiaGargalos.isEmpty &&
            data.modoOperacao.isEmpty &&
            data.alunosEmRisco.isEmpty &&
            data.cobrancasPendentes.isEmpty) {
          return const _IaActionHistory();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommandHeader(total: data.filaAcoes.length),
            if (data.modoOperacao.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ModoOperacaoSection(itens: data.modoOperacao),
              const SizedBox(height: 16),
            ],
            if (data.alunosScore.isNotEmpty) ...[
              const SizedBox(height: 10),
              _FocuxRadarSection(scores: data.alunosScore),
              const SizedBox(height: 16),
            ],
            if (data.autonomiaGargalos.isNotEmpty) ...[
              const SizedBox(height: 10),
              _AutonomiaGargalosSection(gargalos: data.autonomiaGargalos),
              const SizedBox(height: 16),
            ],
            if (data.filaAcoes.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...data.filaAcoes.map((acao) => _CommandActionCard(action: acao)),
              const SizedBox(height: 16),
            ],
            if (data.agendaHoje.isNotEmpty) ...[
              Text(
                'Agenda de Hoje',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...data.agendaHoje.map((ag) => _AgendaTile(agendamento: ag)),
              const SizedBox(height: 16),
            ],
            const _IaActionHistory(),
          ],
        );
      },
    );
  }
}

class _IaActionHistory extends ConsumerStatefulWidget {
  const _IaActionHistory();

  @override
  ConsumerState<_IaActionHistory> createState() => _IaActionHistoryState();
}

class _IaActionHistoryState extends ConsumerState<_IaActionHistory> {
  String _status = '';

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(dashboardRepositoryProvider);
    final primary = Theme.of(context).colorScheme.primary;
    return FutureBuilder<List<FilaAcaoResumo>>(
      future: repo.getIaCommandActions(status: _status),
      builder: (context, snapshot) {
        final actions = snapshot.data ?? const <FilaAcaoResumo>[];
        if (snapshot.connectionState == ConnectionState.waiting &&
            actions.isEmpty) {
          return const SizedBox.shrink();
        }
        if (actions.isEmpty && _status.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Histórico IA',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: Theme.of(context).colorScheme.surface,
                  ),
                  child: DropdownButton<String>(
                    value: _status,
                    underline: const SizedBox.shrink(),
                    iconEnabledColor: primary,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: Theme.of(context).textTheme.bodySmall,
                    borderRadius: BorderRadius.circular(EagleTokens.radiusMd),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Todas')),
                      DropdownMenuItem(value: 'ABERTO', child: Text('Abertas')),
                      DropdownMenuItem(value: 'ADIADO', child: Text('Adiadas')),
                      DropdownMenuItem(
                        value: 'CONCLUIDO',
                        child: Text('Concluídas'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _status = value ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (actions.isEmpty)
              Text(
                'Nenhuma ação IA neste filtro.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...actions
                  .take(6)
                  .map((action) => _IaHistoryTile(action: action)),
          ],
        );
      },
    );
  }
}

class _IaHistoryTile extends ConsumerWidget {
  final FilaAcaoResumo action;

  const _IaHistoryTile({required this.action});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(EagleTokens.radiusSm),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.titulo,
                  style: TextStyle(
                    color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  action.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Pill(label: action.status, color: primary),
                    if (action.alunoId != null)
                      _Pill(label: 'Aluno ${action.alunoId}', color: primary),
                  ],
                ),
              ],
            ),
          ),
          if (action.status != 'ABERTO')
            TextButton(
              onPressed: () async {
                await ref
                    .read(dashboardRepositoryProvider)
                    .reopenCommandAction(action.actionKey);
                ref.invalidate(commandCenterProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ação reaberta.')),
                  );
                }
              },
              child: const Text('Reabrir'),
            ),
        ],
      ),
    );
  }
}

class _ModoOperacaoSection extends StatelessWidget {
  final List<ModoOperacaoItem> itens;

  const _ModoOperacaoSection({required this.itens});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final top = itens.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: primary, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Modo operação',
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Pill(label: '${itens.length} focos', color: primary),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Prioridades com maior impacto no seu dia — abra e execute em sequência.',
            style: TextStyle(color: mute, fontSize: 12.5, height: 1.3),
          ),
          const SizedBox(height: 12),
          for (final item in top) ...[
            _ModoOperacaoTile(item: item),
            if (item != top.last)
              Divider(
                height: 16,
                color: isDark ? EagleTokens.darkLine : EagleTokens.line,
              ),
          ],
        ],
      ),
    );
  }
}

class _ModoOperacaoTile extends StatelessWidget {
  final ModoOperacaoItem item;

  const _ModoOperacaoTile({required this.item});

  Color _categoriaColor(String categoria, Color primary) {
    switch (categoria.toUpperCase()) {
      case 'FINANCEIRO':
        return EagleTokens.warn;
      case 'ALUNO':
      case 'RELACIONAMENTO':
        return EagleTokens.good;
      default:
        return primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final catColor = _categoriaColor(item.categoria, primary);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '${item.impactScore}',
                  style: TextStyle(
                    color: catColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: mute, fontSize: 12.2, height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Pill(label: item.prioridade, color: catColor, filled: true),
                      _Pill(label: item.categoria, color: primary),
                      if (item.motivo.isNotEmpty)
                        _Pill(
                          label: item.motivo,
                          color: mute,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => context.push(item.acaoUrl),
                child: Text(item.ctaLabel),
              ),
            ],
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row,
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => context.push(item.acaoUrl),
                child: Text(item.ctaLabel),
              ),
            ],
          );
        }
        return row;
      },
    );
  }
}

class _FocuxRadarSection extends ConsumerStatefulWidget {
  final List<AlunoScoreResumo> scores;

  const _FocuxRadarSection({required this.scores});

  @override
  ConsumerState<_FocuxRadarSection> createState() => _FocuxRadarSectionState();
}

class _FocuxRadarSectionState extends ConsumerState<_FocuxRadarSection> {
  bool _syncing = false;

  Future<void> _syncSnapshots(BuildContext context) async {
    setState(() => _syncing = true);
    try {
      await ref.read(dashboardRepositoryProvider).runFocuxScoreSnapshots();
      ref.invalidate(commandCenterProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Radar Focux atualizado.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível atualizar o Radar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final topScores = widget.scores.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_outlined, color: primary, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Radar Focux',
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Pill(label: '${widget.scores.length} sinais', color: primary),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: _syncing ? null : () => _syncSnapshots(context),
                icon:
                    _syncing
                        ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.insights_rounded, size: 18),
                tooltip: 'Atualizar Radar Focux',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Fila inteligente por score, risco, ritmo e próxima melhor ação.',
            style: TextStyle(color: mute, fontSize: 12.5, height: 1.3),
          ),
          const SizedBox(height: 12),
          for (final score in topScores) ...[
            _AlunoScoreTile(score: score),
            if (score != topScores.last)
              Divider(
                height: 16,
                color: isDark ? EagleTokens.darkLine : EagleTokens.line,
              ),
          ],
        ],
      ),
    );
  }
}

class _AlunoScoreTile extends ConsumerWidget {
  final AlunoScoreResumo score;

  const _AlunoScoreTile({required this.score});

  Color _riskColor(String risco, Color primary) {
    final normalized = risco.toLowerCase();
    if (normalized.contains('alto')) return EagleTokens.bad;
    if (normalized.contains('moderado')) return EagleTokens.warn;
    return primary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final riskColor = _riskColor(score.risco, primary);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final scoreColor =
        score.score >= 80
            ? EagleTokens.good
            : score.score >= 55
            ? primary
            : riskColor;

    final badge = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          '${score.score}',
          style: TextStyle(
            color: scoreColor,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          score.alunoNome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          score.narrativa,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: mute, fontSize: 12.2, height: 1.25),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _Pill(label: score.prioridade, color: riskColor, filled: true),
            if (score.deltaScore != null)
              _Pill(
                label: _deltaLabel(score.deltaScore!),
                color: _deltaColor(score.deltaScore!, primary),
                filled: score.deltaScore! < 0,
              ),
            _Pill(label: score.ritmo, color: primary),
            _Pill(label: score.risco, color: riskColor),
            _Pill(label: score.proximaAcao, color: primary),
          ],
        ),
      ],
    );
    final action = IconButton.filledTonal(
      onPressed: () => context.push(score.acaoUrl),
      icon: const Icon(Icons.arrow_forward_rounded),
      tooltip: 'Abrir aluno',
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openScoreHistory(context, ref, score),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      badge,
                      const SizedBox(width: 10),
                      Expanded(child: copy),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: action,
                    ),
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                badge,
                const SizedBox(width: 10),
                Expanded(child: copy),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 52),
                  child: action,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void _openScoreHistory(
  BuildContext context,
  WidgetRef ref,
  AlunoScoreResumo score,
) {
  final repo = ref.read(dashboardRepositoryProvider);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder:
        (context) => _FocuxScoreHistorySheet(
          score: score,
          future: repo.getFocuxScoreSnapshots(score.alunoId),
        ),
  );
}

class _FocuxScoreHistorySheet extends StatelessWidget {
  final AlunoScoreResumo score;
  final Future<List<FocuxScoreSnapshotResumo>> future;

  const _FocuxScoreHistorySheet({required this.score, required this.future});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.76;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          score.alunoNome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Histórico do Radar Focux',
                          style: TextStyle(
                            color: mute,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ScoreRing(score: score.score),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                score.narrativa,
                style: TextStyle(color: mute, fontSize: 13.2, height: 1.35),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Pill(label: score.prioridade, color: primary, filled: true),
                  if (score.deltaScore != null)
                    _Pill(
                      label: _deltaLabel(score.deltaScore!),
                      color: _deltaColor(score.deltaScore!, primary),
                      filled: score.deltaScore! < 0,
                    ),
                  _Pill(label: score.risco, color: primary),
                  _Pill(label: score.proximaAcao, color: primary),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: FutureBuilder<List<FocuxScoreSnapshotResumo>>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final snapshots = snapshot.data ?? const [];
                    if (snapshots.isEmpty) {
                      return _EmptyHistoryState(score: score);
                    }
                    return ListView.separated(
                      itemCount: snapshots.length,
                      separatorBuilder:
                          (_, __) => Divider(
                            height: 18,
                            color:
                                isDark
                                    ? EagleTokens.darkLine
                                    : EagleTokens.line,
                          ),
                      itemBuilder:
                          (context, index) =>
                              _ScoreHistoryRow(snapshot: snapshots[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;

  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final color =
        score >= 80
            ? EagleTokens.good
            : score >= 55
            ? primary
            : EagleTokens.bad;
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Center(
        child: Text(
          '$score',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  final AlunoScoreResumo score;

  const _EmptyHistoryState({required this.score});

  @override
  Widget build(BuildContext context) {
    final mute =
        Theme.of(context).brightness == Brightness.dark
            ? EagleTokens.darkInkMute
            : EagleTokens.inkMute;
    return Center(
      child: Text(
        'A primeira leitura histórica de ${score.alunoNome} ainda não foi registrada.',
        textAlign: TextAlign.center,
        style: TextStyle(color: mute, fontSize: 13, height: 1.35),
      ),
    );
  }
}

class _ScoreHistoryRow extends StatelessWidget {
  final FocuxScoreSnapshotResumo snapshot;

  const _ScoreHistoryRow({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final scoreColor =
        snapshot.score >= 80
            ? EagleTokens.good
            : snapshot.score >= 55
            ? primary
            : EagleTokens.bad;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _shortDate(snapshot.dataReferencia),
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 5),
              _ScoreBar(value: snapshot.score, color: scoreColor),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${snapshot.score} pts',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      snapshot.ritmo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mute,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                snapshot.narrativa,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: mute, fontSize: 12.5, height: 1.3),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Pill(label: snapshot.prioridade, color: scoreColor),
                  _Pill(label: snapshot.risco, color: primary),
                  _Pill(label: snapshot.proximaAcao, color: primary),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final int value;
  final Color color;

  const _ScoreBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final width = 42 * (value.clamp(0, 100) / 100);
    return Stack(
      children: [
        Container(
          width: 42,
          height: 5,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Container(
          width: width,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

String _shortDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String _deltaLabel(int delta) {
  if (delta == 0) return 'estável';
  return '${delta > 0 ? '+' : ''}$delta pts';
}

Color _deltaColor(int delta, Color primary) {
  if (delta < 0) return EagleTokens.bad;
  if (delta > 0) return EagleTokens.good;
  return primary;
}

class _CommandHeader extends StatelessWidget {
  final int total;

  const _CommandHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Central de Comando',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: primary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$total acoes',
            style: TextStyle(
              color: primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _AutonomiaGargalosSection extends StatelessWidget {
  final List<AutonomiaGargaloResumo> gargalos;

  const _AutonomiaGargalosSection({required this.gargalos});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final topGargalos = gargalos.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_outlined, color: primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gargalos de autonomia',
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Pill(label: '${gargalos.length} ativos', color: primary),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Priorize alunos que pediram ajuda na pratica e ainda nao fecharam a tarefa.',
            style: TextStyle(color: mute, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          for (final gargalo in topGargalos) ...[
            _AutonomiaGargaloTile(gargalo: gargalo),
            if (gargalo != topGargalos.last)
              Divider(
                height: 16,
                color: isDark ? EagleTokens.darkLine : EagleTokens.line,
              ),
          ],
        ],
      ),
    );
  }
}

class _AutonomiaGargaloTile extends StatelessWidget {
  final AutonomiaGargaloResumo gargalo;

  const _AutonomiaGargaloTile({required this.gargalo});

  String _actionLabel(String action) {
    switch (action.toUpperCase()) {
      case 'CLICKED':
        return 'Clicou';
      case 'COMPLETED':
        return 'Concluiu';
      case 'VIEWED':
        return 'Viu';
      default:
        return action;
    }
  }

  String _dateLabel(String? value) {
    final parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) return '--';
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final openClicks = gargalo.cliques - gargalo.concluidos;
    final pendingLabel =
        openClicks == 1 ? '1 clique aberto' : '$openClicks cliques abertos';

    final icon = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: EagleTokens.warn.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(EagleTokens.radiusSm),
      ),
      child: const Icon(
        Icons.touch_app_outlined,
        color: EagleTokens.warn,
        size: 18,
      ),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          gargalo.alunoNome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          gargalo.taskTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: mute, fontSize: 12.5, height: 1.25),
        ),
        const SizedBox(height: 4),
        Text(
          _suggestedAction(gargalo.taskId),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _Pill(label: pendingLabel, color: EagleTokens.warn),
            _Pill(label: gargalo.prioridade, color: primary),
            _Pill(label: _actionLabel(gargalo.ultimaAcao), color: primary),
            _Pill(label: _dateLabel(gargalo.ultimoEventoEm), color: mute),
          ],
        ),
      ],
    );
    final action = IconButton.filledTonal(
      onPressed: () => context.push(gargalo.acaoUrl),
      icon: const Icon(Icons.arrow_forward_rounded),
      tooltip: 'Abrir aluno',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Expanded(child: copy),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: action,
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(width: 10),
            Expanded(child: copy),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 52),
              child: action,
            ),
          ],
        );
      },
    );
  }
}

String _suggestedAction(String taskId) {
  return switch (taskId) {
    'perfil-base' || 'foto-dados' =>
      'Peca os dados que faltam e explique por que isso melhora o acompanhamento.',
    'medida-recente' =>
      'Convide o aluno a registrar medida ou envie um lembrete com prazo curto.',
    'chat-contexto' =>
      'Abra conversa com uma pergunta objetiva para destravar o contexto.',
    'agenda-semana' => 'Confirme o melhor horario e reduza atrito de agenda.',
    'financeiro' => 'Oriente regularizacao antes de bloquear acesso.',
    'treino-semana' => 'Confirme treino ativo e remova barreira para executar.',
    _ => 'Abra a ficha e resolva o proximo passo com o aluno.',
  };
}

class _CommandActionCard extends ConsumerWidget {
  final FilaAcaoResumo action;

  const _CommandActionCard({required this.action});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final severityColor = _severityColor(action.severidade, primary);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkCardHi : EagleTokens.card;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(
                label: action.prioridade,
                color: severityColor,
                filled: true,
              ),
              const SizedBox(width: 8),
              _Pill(label: action.severidade, color: severityColor),
              const SizedBox(width: 8),
              if (action.iaSugerida) _Pill(label: 'IA', color: primary),
              const Spacer(),
              Icon(Icons.schedule_rounded, size: 16, color: severityColor),
              const SizedBox(width: 4),
              Text(
                action.sla,
                style: TextStyle(
                  color: severityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            action.titulo,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            action.descricao,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
              fontSize: 13,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  action.responsavel,
                  style: TextStyle(
                    color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await ref
                      .read(dashboardRepositoryProvider)
                      .completeCommandAction(action.actionKey);
                  ref.invalidate(commandCenterProvider);
                },
                child: const Text('Concluir'),
              ),
              TextButton(
                onPressed: () async {
                  await ref
                      .read(dashboardRepositoryProvider)
                      .snoozeCommandAction(action.actionKey);
                  ref.invalidate(commandCenterProvider);
                },
                child: const Text('Adiar'),
              ),
              FilledButton(
                onPressed: () => context.push(action.acaoUrl),
                style: FilledButton.styleFrom(backgroundColor: primary),
                child: Text(action.ctaLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity, Color fallback) {
    if (severity == 'ALTA') return EagleTokens.bad;
    if (severity == 'MEDIA') return EagleTokens.warn;
    return fallback;
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const _Pill({required this.label, required this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  final AgendamentoResumo agendamento;

  const _AgendaTile({required this.agendamento});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.event)),
        title: Text(
          agendamento.nomeAluno,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Horario: ${agendamento.horario.substring(11, 16)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                agendamento.status == 'CONFIRMADO'
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            agendamento.status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color:
                  agendamento.status == 'CONFIRMADO'
                      ? const Color(0xFF166534)
                      : const Color(0xFF1F2937),
            ),
          ),
        ),
      ),
    );
  }
}
