import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../data/treino_repository.dart';
import '../providers/treinos_provider.dart';
import '../../../core/utils/friendly_error.dart';

class TreinoDetailScreen extends ConsumerWidget {
  final int treinoId;
  const TreinoDetailScreen({super.key, required this.treinoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinoAsync = ref.watch(treinoProvider(treinoId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      body: treinoAsync.when(
        loading:
            () => Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data:
            (treino) => _TreinoDetailBody(
              treino: treino,
              treinoId: treinoId,
              isDark: isDark,
              ref: ref,
            ),
      ),
    );
  }
}

class _TreinoDetailBody extends StatelessWidget {
  final Treino treino;
  final int treinoId;
  final bool isDark;
  final WidgetRef ref;
  const _TreinoDetailBody({
    required this.treino,
    required this.treinoId,
    required this.isDark,
    required this.ref,
  });

  Future<void> _openMenu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
        final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mute.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Opcoes do treino',
                  style: TextStyle(
                    color: ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _MenuActionTile(
                  icon: Icons.add_circle_outline,
                  label: 'Adicionar exercicio',
                  onTap: () => Navigator.pop(sheetContext, 'add'),
                ),
                _MenuActionTile(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Atribuir a aluno',
                  onTap: () => Navigator.pop(sheetContext, 'assign'),
                ),
                _MenuActionTile(
                  icon: Icons.copy_outlined,
                  label: 'Duplicar treino',
                  onTap: () => Navigator.pop(sheetContext, 'duplicate'),
                ),
                _MenuActionTile(
                  icon: Icons.bookmark_border,
                  label: 'Salvar como template',
                  onTap: () => Navigator.pop(sheetContext, 'template'),
                ),
                _MenuActionTile(
                  icon: Icons.delete_outline,
                  label: 'Excluir treino',
                  color: EagleTokens.bad,
                  onTap: () => Navigator.pop(sheetContext, 'delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || action == null) {
      return;
    }

    final repo = ref.read(treinoRepositoryProvider);

    switch (action) {
      case 'add':
        final added = await context.push<bool>(
          '/treinos/$treinoId/exercicios/add',
        );
        if (added == true) {
          ref.invalidate(treinoProvider(treinoId));
        }
        break;
      case 'assign':
        try {
          final alunos = await ref.read(alunosProvider.future);
          if (!context.mounted) return;
          int? alunoId = alunos.isEmpty ? null : alunos.first.id;
          final selected = await showDialog<int>(
            context: context,
            builder:
                (dialogContext) => StatefulBuilder(
                  builder:
                      (dialogContext, setDialogState) => AlertDialog(
                        title: const Text('Atribuir treino'),
                        content:
                            alunos.isEmpty
                                ? const Text(
                                  'Nenhum aluno cadastrado encontrado.',
                                )
                                : DropdownButtonFormField<int>(
                                  value: alunoId,
                                  decoration: const InputDecoration(
                                    labelText: 'Aluno',
                                    border: OutlineInputBorder(),
                                  ),
                                  items:
                                      alunos
                                          .map(
                                            (aluno) => DropdownMenuItem<int>(
                                              value: aluno.id,
                                              child: Text(aluno.nome),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (value) =>
                                          setDialogState(() => alunoId = value),
                                ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed:
                                alunoId == null
                                    ? null
                                    : () =>
                                        Navigator.pop(dialogContext, alunoId),
                            child: const Text('Atribuir'),
                          ),
                        ],
                      ),
                ),
          );
          if (selected == null) return;
          await repo.atribuirAluno(treinoId, selected);
          ref.invalidate(treinoProvider(treinoId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Treino atribuido ao aluno.')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
          }
        }
        break;
      case 'duplicate':
        try {
          await repo.duplicar(treinoId);
          ref.invalidate(treinosProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Treino duplicado com sucesso.')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
          }
        }
        break;
      case 'template':
        try {
          await repo.salvarComoTemplate(treinoId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Treino salvo como template.')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
          }
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: const Text('Excluir treino?'),
                content: const Text(
                  'Essa acao remove o treino e seus vinculos. Ela nao pode ser desfeita.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: EagleTokens.bad,
                    ),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Excluir'),
                  ),
                ],
              ),
        );
        if (confirm != true) break;
        try {
          await repo.excluirTreino(treinoId);
          ref.invalidate(treinosProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Treino excluido.')));
            context.pop(true);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(treinoRepositoryProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final primaryDeep = BrandPalette.deep(primary);
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final orderedExercises = [...treino.exercicios]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));

    // Group by muscle
    final grouped = <String, List<TreinoExercicioItem>>{};
    for (final te in treino.exercicios) {
      final group =
          te.exercicio.musculoAlvo?.isNotEmpty == true
              ? te.exercicio.musculoAlvo!
              : 'Outros';
      grouped.putIfAbsent(group, () => []).add(te);
    }

    return CustomScrollView(
      slivers: [
        // Hero AppBar
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF0A0F1E) : primaryDeep,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Sugestão IA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Gradient base
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: const GradientRotation(160 * math.pi / 180),
                      colors:
                          isDark
                              ? [primaryDeep, const Color(0xFF0A0F1E)]
                              : [primary, primaryDeep],
                      stops: const [0.0, 0.85],
                    ),
                  ),
                ),
                // Grid texture — white 6% opacity, 26×26px cells
                CustomPaint(painter: const _GridTexturePainter()),
                // Content
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 100, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Cover tile & Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 30,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 56,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 10,
                                  child: Text(
                                    'TREINO',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ALUNO FOCO',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    treino.nome,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.timer_outlined,
                                        size: 13,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '45min',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '·',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${treino.exercicios.length} ex.',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Action row
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                context.push(
                                  '/checkin/executar',
                                  extra: treinoId,
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      color: primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Iniciar treino',
                                      style: TextStyle(
                                        color: primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => _openMenu(context),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.more_horiz,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stats Ribbon — design: Duração / Exercícios / Volume
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Builder(
              builder: (context) {
                // Estimated duration: 3–4 min per exercise (rough)
                final durMin = (treino.exercicios.length * 3.5).round();
                // Volume: sum of series × (int from repeticoes) × cargaKg
                double vol = 0;
                for (final te in treino.exercicios) {
                  final reps =
                      int.tryParse(te.repeticoes.split('x').last.trim()) ??
                      int.tryParse(te.repeticoes) ??
                      0;
                  vol += te.series * reps * (te.cargaKg ?? 0);
                }
                return Row(
                  children: [
                    _MiniMetric(
                      label: 'Duração',
                      value: '~${durMin}min',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _MiniMetric(
                      label: 'Exercícios',
                      value: '${treino.exercicios.length}',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _MiniMetric(
                      label: 'Volume',
                      value:
                          vol > 0
                              ? '${(vol / 1000).toStringAsFixed(1)}t'
                              : '${grouped.keys.length} ${grouped.keys.length == 1 ? 'grupo' : 'grupos'}',
                      isDark: isDark,
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Exercise list grouped
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercícios',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final adicionado = await context.push<bool>(
                      '/treinos/$treinoId/exercicios/add',
                    );
                    if (adicionado == true) {
                      ref.invalidate(treinoProvider(treinoId));
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 14, color: primary),
                      const SizedBox(width: 4),
                      Text(
                        'Adicionar',
                        style: TextStyle(
                          color: primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (treino.exercicios.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('Nenhum exercício no treino.')),
          )
        else ...[
          SliverToBoxAdapter(
            child: _DraggableExerciseOrderPanel(
              treinoId: treinoId,
              exercises: orderedExercises,
              isDark: isDark,
              primary: primary,
              ref: ref,
            ),
          ),
          ...grouped.entries.map(
            (entry) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                      child: Row(
                        children: [
                          Text(
                            entry.key.toUpperCase(),
                            style: TextStyle(
                              color:
                                  isDark
                                      ? EagleTokens.darkInkMute
                                      : EagleTokens.inkMute,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 0.5,
                              color:
                                  isDark
                                      ? EagleTokens.darkLine
                                      : EagleTokens.line,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.value.length} ex.',
                            style: TextStyle(
                              color:
                                  isDark
                                      ? EagleTokens.darkInkMute
                                      : EagleTokens.inkMute,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isDark ? EagleTokens.darkLine : EagleTokens.line,
                        ),
                      ),
                      child: Column(
                        children:
                            entry.value.asMap().entries.map((e) {
                              final i = e.key;
                              final te = e.value;
                              final globalIndex = orderedExercises.indexWhere(
                                (item) => item.id == te.id,
                              );
                              Future<void> reorder(int direction) async {
                                final ids =
                                    orderedExercises
                                        .map((item) => item.id)
                                        .toList();
                                final targetIndex = globalIndex + direction;
                                if (globalIndex < 0 ||
                                    targetIndex < 0 ||
                                    targetIndex >= ids.length) {
                                  return;
                                }
                                final current = ids.removeAt(globalIndex);
                                ids.insert(targetIndex, current);
                                try {
                                  await repo.reordenarExercicios(treinoId, ids);
                                  ref.invalidate(treinoProvider(treinoId));
                                } catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao reordenar: $error',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }

                              return _ExercicioRow(
                                te: te,
                                index: globalIndex + 1,
                                isDark: isDark,
                                primary: primary,
                                primarySoft: primarySoft,
                                isLast: i == entry.value.length - 1,
                                canMoveUp: globalIndex > 0,
                                canMoveDown:
                                    globalIndex < orderedExercises.length - 1,
                                onMoveUp: () => reorder(-1),
                                onMoveDown: () => reorder(1),
                                onDuplicate: () async {
                                  try {
                                    await repo.duplicarExercicio(
                                      treinoId,
                                      te.id,
                                    );
                                    ref.invalidate(treinoProvider(treinoId));
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Erro ao duplicar: $error',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                onRemove: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (ctx) => AlertDialog(
                                          title: const Text(
                                            'Remover exercício',
                                          ),
                                          content: Text(
                                            'Remover "${te.exercicio.nome}" do treino?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      Navigator.pop(ctx, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    EagleTokens.bad,
                                              ),
                                              onPressed:
                                                  () =>
                                                      Navigator.pop(ctx, true),
                                              child: const Text('Remover'),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true && context.mounted) {
                                    try {
                                      await repo.removerExercicio(
                                        treinoId,
                                        te.id,
                                      );
                                      ref.invalidate(treinoProvider(treinoId));
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Erro: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _DraggableExerciseOrderPanel extends StatelessWidget {
  final int treinoId;
  final List<TreinoExercicioItem> exercises;
  final bool isDark;
  final Color primary;
  final WidgetRef ref;

  const _DraggableExerciseOrderPanel({
    required this.treinoId,
    required this.exercises,
    required this.isDark,
    required this.primary,
    required this.ref,
  });

  Future<void> _persistOrder(
    BuildContext context,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final ids = exercises.map((item) => item.id).toList();
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);

    try {
      await ref
          .read(treinoRepositoryProvider)
          .reordenarExercicios(treinoId, ids);
      ref.invalidate(treinoProvider(treinoId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao reordenar: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final card = isDark ? EagleTokens.darkCard : EagleTokens.card;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: line),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Row(
                children: [
                  Icon(Icons.drag_indicator_rounded, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ordem do treino',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${exercises.length} ex.',
                    style: TextStyle(
                      color: mute,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 10,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: child,
                );
              },
              onReorder:
                  (oldIndex, newIndex) =>
                      _persistOrder(context, oldIndex, newIndex),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final item = exercises[index];
                return _DraggableOrderTile(
                  key: ValueKey('drag-order-${item.id}'),
                  item: item,
                  index: index + 1,
                  dragIndex: index,
                  isDark: isDark,
                  primary: primary,
                  isLast: index == exercises.length - 1,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DraggableOrderTile extends StatelessWidget {
  final TreinoExercicioItem item;
  final int index;
  final int dragIndex;
  final bool isDark;
  final Color primary;
  final bool isLast;

  const _DraggableOrderTile({
    super.key,
    required this.item,
    required this.index,
    required this.dragIndex,
    required this.isDark,
    required this.primary,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        border:
            isLast ? null : Border(bottom: BorderSide(color: line, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                color: primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.exercicio.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.series}x${item.repeticoes} · ${item.descansoSegundos ?? 60}s',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mute,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ReorderableDragStartListener(
            index: dragIndex,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.drag_handle_rounded, color: mute, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuActionTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = color ?? (isDark ? EagleTokens.darkInk : EagleTokens.ink);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(icon, color: ink),
      title: Text(
        label,
        style: TextStyle(color: ink, fontWeight: FontWeight.w600),
      ),
      trailing: Icon(Icons.chevron_right, color: ink),
      tileColor: Colors.transparent,
      onTap: onTap,
      horizontalTitleGap: 10,
      minLeadingWidth: 24,
      dense: false,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.darkCard : EagleTokens.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? EagleTokens.darkLine : EagleTokens.line,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercicioRow extends StatelessWidget {
  final TreinoExercicioItem te;
  final int index;
  final bool isDark;
  final Color primary;
  final Color primarySoft;
  final bool isLast;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;

  const _ExercicioRow({
    required this.te,
    required this.index,
    required this.isDark,
    required this.primary,
    required this.primarySoft,
    required this.isLast,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDuplicate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final hasMedia = te.exercicio.hasPlayableMedia;
    final isAdvanced = te.tipoSerie != 'NORMAL';
    final trustColor = _trustColor(te.exercicio, primary);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        border:
            isLast ? null : Border(bottom: BorderSide(color: line, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: TextStyle(
                color: primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  te.exercicio.nome,
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${te.series}×${te.repeticoes}',
                      style: TextStyle(
                        color: ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: mute,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${te.cargaKg ?? 0}kg',
                      style: TextStyle(
                        color: ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: mute,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.timer_outlined, size: 11, color: mute),
                    const SizedBox(width: 3),
                    Text(
                      '${te.descansoSegundos ?? 60}s',
                      style: TextStyle(color: mute, fontSize: 11.5),
                    ),
                  ],
                ),
                if (isAdvanced ||
                    hasMedia ||
                    te.observacoes?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _ExerciseMeta(
                        icon: _trustIcon(te.exercicio),
                        text: te.exercicio.mediaTrustLabel,
                        color: trustColor,
                      ),
                      if (isAdvanced)
                        _ExerciseMeta(
                          icon:
                              te.tipoSerie == 'SUPERSET'
                                  ? Icons.link_rounded
                                  : Icons.trending_down_rounded,
                          text:
                              te.tipoSerie == 'SUPERSET'
                                  ? 'superset ${te.grupoSuperset ?? '-'}'
                                  : 'drop set',
                          color:
                              te.tipoSerie == 'SUPERSET'
                                  ? primary
                                  : EagleTokens.warn,
                        ),
                      if (te.observacoes?.trim().isNotEmpty == true)
                        _ExerciseMeta(
                          icon: Icons.notes_rounded,
                          text: te.observacoes!.trim(),
                          color: mute,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            iconColor: mute,
            iconSize: 20,
            onSelected: (val) {
              if (val == 'up') onMoveUp();
              if (val == 'down') onMoveDown();
              if (val == 'duplicate') onDuplicate();
              if (val == 'remove') onRemove();
            },
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    value: 'up',
                    enabled: canMoveUp,
                    child: const Text('Mover para cima'),
                  ),
                  PopupMenuItem(
                    value: 'down',
                    enabled: canMoveDown,
                    child: const Text('Mover para baixo'),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicar item'),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text(
                      'Remover',
                      style: TextStyle(color: EagleTokens.bad),
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }
}

/// Grid texture painter — white lines 6% opacity, 26×26px cells.
/// Matches auth_shell.dart _AuthGridPainter; reused on hero surfaces.
Color _trustColor(Exercicio exercicio, Color primary) {
  return switch (exercicio.mediaTrustLevel) {
    'READY' => exercicio.isPersonalUpload ? primary : EagleTokens.good,
    'NO_VIDEO' => EagleTokens.bad,
    _ => EagleTokens.warn,
  };
}

IconData _trustIcon(Exercicio exercicio) {
  return switch (exercicio.mediaTrustLevel) {
    'READY' =>
      exercicio.isPersonalUpload
          ? Icons.workspace_premium_rounded
          : Icons.verified_rounded,
    'NO_VIDEO' => Icons.videocam_off_outlined,
    _ => Icons.rate_review_outlined,
  };
}

class _ExerciseMeta extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color color;

  const _ExerciseMeta({this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _GridTexturePainter extends CustomPainter {
  const _GridTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
