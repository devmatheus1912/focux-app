import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../../exercicios/screens/widgets/substituir_exercicio_bottom_sheet.dart';
import '../data/treino_repository.dart';
import '../providers/treinos_provider.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/theme/shell_chrome.dart';

String _workoutContextLabel(Treino treino, String? alunoNome) {
  final name = alunoNome?.trim();
  if (name != null && name.isNotEmpty) return name;
  if (treino.isTemplate) return 'Template base';
  return 'Plano base';
}

String _formatLoadKg(double? value) {
  if (value == null || value <= 0) return '—';
  if (value == value.roundToDouble()) return '${value.toStringAsFixed(0)}kg';
  return '${value.toStringAsFixed(1)}kg';
}

String _displayWorkoutName(String raw) {
  var name = raw.trim();
  if (name.isEmpty) return name;
  const fixes = {
    ' Forca': ' Força',
    ' forca': ' Força',
    ' FORCA': ' Força',
    'Forca ': 'Força ',
    'Forca': 'Força',
  };
  for (final entry in fixes.entries) {
    name = name.replaceAll(entry.key, entry.value);
  }
  return name;
}

String _workoutGroupLabel(TreinoExercicioItem te) {
  final grupo = te.exercicio.grupoMuscularPrimario;
  if (grupo != null) {
    final label = TaxonomyLabels.grupo[grupo];
    if (label != null && label.isNotEmpty) return label.toUpperCase();
  }
  final alvo = te.exercicio.musculoAlvo?.trim();
  if (alvo != null && alvo.isNotEmpty) return alvo.toUpperCase();
  return 'OUTROS';
}

bool _showsExerciseGroupHeader(List<TreinoExercicioItem> items, int index) {
  if (index <= 0) return true;
  return _workoutGroupLabel(items[index]) !=
      _workoutGroupLabel(items[index - 1]);
}

int _localIndexInGroup(List<TreinoExercicioItem> items, int index) {
  final group = _workoutGroupLabel(items[index]);
  var local = 1;
  for (var i = index - 1; i >= 0; i--) {
    if (_workoutGroupLabel(items[i]) != group) break;
    local++;
  }
  return local;
}

int _groupExerciseCount(List<TreinoExercicioItem> items, int index) {
  final group = _workoutGroupLabel(items[index]);
  return items.where((item) => _workoutGroupLabel(item) == group).length;
}

bool _isLastInExerciseGroup(List<TreinoExercicioItem> items, int index) {
  if (index >= items.length - 1) return true;
  return _workoutGroupLabel(items[index]) !=
      _workoutGroupLabel(items[index + 1]);
}

class TreinoDetailScreen extends ConsumerWidget {
  final int treinoId;
  final int? alunoId;
  final String? alunoNome;

  const TreinoDetailScreen({
    super.key,
    required this.treinoId,
    this.alunoId,
    this.alunoNome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinoAsync = ref.watch(treinoProvider(treinoId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _popTreinoDetail(context, alunoId: alunoId);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: treinoAsync.when(
          loading:
              () => SafeArea(
                child: Stack(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(TokensStrip.s5, 86, 20, 0),
                      child: SkeletonList(count: 6),
                    ),
                    Positioned(
                      top: 8,
                      left: TokensStrip.s5 - 4,
                      child: _TreinoDetailBackButton(alunoId: alunoId),
                    ),
                  ],
                ),
              ),
        error:
            (e, _) => _DetailErrorState(
              isDark: isDark,
              primary: primary,
              onRetry: () => ref.invalidate(treinoProvider(treinoId)),
              onBack: () => _popTreinoDetail(context, alunoId: alunoId),
            ),
        data:
            (treino) => _TreinoDetailBody(
              treino: treino,
              treinoId: treinoId,
              alunoId: alunoId,
              alunoNome: alunoNome,
              isDark: isDark,
              ref: ref,
            ),
        ),
      ),
    );
  }
}

void _popTreinoDetail(BuildContext context, {int? alunoId}) {
  if (alunoId != null) {
    safePopOrGo(context, '/alunos/$alunoId/treinos-list');
    return;
  }
  safePopOrGo(context, '/treinos');
}

class _TreinoDetailBackButton extends StatelessWidget {
  final int? alunoId;

  const _TreinoDetailBackButton({required this.alunoId});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);

    return IconButton(
      onPressed: () => _popTreinoDetail(context, alunoId: alunoId),
      icon: Container(
        width: 38,
        height: 38,
        decoration: chrome.headerAction(radius: 12),
        child: Center(
          child: FxIcon(name: 'arrow-left', size: 18, color: chrome.ink),
        ),
      ),
    );
  }
}

class _TreinoDetailBody extends StatelessWidget {
  final Treino treino;
  final int treinoId;
  final int? alunoId;
  final String? alunoNome;
  final bool isDark;
  final WidgetRef ref;
  const _TreinoDetailBody({
    required this.treino,
    required this.treinoId,
    required this.alunoId,
    required this.alunoNome,
    required this.isDark,
    required this.ref,
  });

  Future<void> _openMenu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      isScrollControlled: true,
      builder: (sheetContext) {
        final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
        final mute =
            isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.82;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              decoration: fxListCardDecoration(context),
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : EagleTokens.brandSofter,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Opções do treino',
                              style: AppTypography.inter(
                                color: ink,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Atribua, duplique ou salve como modelo.',
                              style: AppTypography.inter(
                                color: mute,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MenuActionTile(
                            icon: Icons.add_circle_outline,
                            label: 'Adicionar exercício',
                            onTap: () => Navigator.pop(sheetContext, 'add'),
                          ),
                          _MenuActionTile(
                            icon: Icons.person_add_alt_1_outlined,
                            label: 'Atribuir a aluno',
                            onTap: () => Navigator.pop(sheetContext, 'assign'),
                          ),
                          _MenuActionTile(
                            icon: Icons.content_copy_rounded,
                            label: 'Copiar para aluno',
                            onTap: () => Navigator.pop(sheetContext, 'clone'),
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
                  ),
                ],
              ),
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
          extra: alunoId == null ? null : {'alunoId': alunoId},
        );
        if (added == true) {
          ref.invalidate(treinoProvider(treinoId));
        }
        break;
      case 'assign':
        try {
          final alunos = await ref.read(alunosProvider.future);
          if (!context.mounted) return;
          final selected = await showModalBottomSheet<int>(
            context: context,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black.withValues(alpha: 0.34),
            isScrollControlled: true,
            builder:
                (dialogContext) =>
                    _AssignWorkoutSheet(alunos: alunos, isDark: isDark),
          );
          if (selected == null) return;
          await repo.atribuirAluno(treinoId, selected);
          ref.invalidate(treinoProvider(treinoId));
          ref.invalidate(treinosProvider);
          ref.invalidate(treinosDoAlunoProvider(selected));
          if (context.mounted) {
            FeedbackHelper.showSuccess(context, 'Treino atribuído ao aluno.');
          }
        } catch (e) {
          if (context.mounted) {
            FeedbackHelper.showError(context, friendlyError(e));
          }
        }
        break;
      case 'clone':
        try {
          final alunos = await ref.read(alunosProvider.future);
          if (!context.mounted) return;
          final selected = await showModalBottomSheet<int>(
            context: context,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black.withValues(alpha: 0.34),
            isScrollControlled: true,
            builder:
                (dialogContext) =>
                    _AssignWorkoutSheet(alunos: alunos, isDark: isDark),
          );
          if (selected == null) return;
          await repo.clonarParaAluno(treinoId, selected);
          ref.invalidate(treinosProvider);
          ref.invalidate(treinosDoAlunoProvider(selected));
          if (context.mounted) {
            FeedbackHelper.showSuccess(
              context,
              'Cópia dedicada criada para o aluno.',
            );
          }
        } catch (e) {
          if (context.mounted) {
            FeedbackHelper.showError(context, friendlyError(e));
          }
        }
        break;
      case 'duplicate':
        try {
          await repo.duplicar(treinoId);
          ref.invalidate(treinosProvider);
          if (context.mounted) {
            FeedbackHelper.showSuccess(
              context,
              'Treino duplicado com sucesso.',
            );
          }
        } catch (e) {
          if (context.mounted) {
            FeedbackHelper.showError(context, friendlyError(e));
          }
        }
        break;
      case 'template':
        try {
          await repo.salvarComoTemplate(treinoId);
          if (context.mounted) {
            FeedbackHelper.showSuccess(context, 'Treino salvo como template.');
          }
        } catch (e) {
          if (context.mounted) {
            FeedbackHelper.showError(context, friendlyError(e));
          }
        }
        break;
      case 'delete':
        final confirm = await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: 0.34),
          builder:
              (dialogContext) =>
                  _DeleteTrainingSheet(title: treino.nome, isDark: isDark),
        );
        if (confirm != true) break;
        HapticFeedback.mediumImpact();
        try {
          await repo.excluirTreino(treinoId);
          ref.invalidate(treinosProvider);
          if (context.mounted) {
            FeedbackHelper.showSuccess(context, 'Treino excluído.');
            context.pop(true);
          }
        } catch (e) {
          if (context.mounted) {
            FeedbackHelper.showError(context, friendlyError(e));
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(treinoRepositoryProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final heroPrimary = BrandPalette.softened(primary, amount: 0.06);
    final heroDeep = BrandPalette.deep(heroPrimary);
    final contextLabel = _workoutContextLabel(treino, alunoNome);
    final displayName = _displayWorkoutName(treino.nome);
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final orderedExercises = [...treino.exercicios]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));

    // Group by muscle taxonomy (consistent labels)
    final grouped = <String, List<TreinoExercicioItem>>{};
    for (final te in orderedExercises) {
      final group = _workoutGroupLabel(te);
      grouped.putIfAbsent(group, () => []).add(te);
    }
    final durationMin = math.max(4, (treino.exercicios.length * 3.5).round());
    double volumeKg = 0;
    for (final te in treino.exercicios) {
      final reps =
          int.tryParse(te.repeticoes.split('x').last.trim()) ??
          int.tryParse(te.repeticoes) ??
          0;
      volumeKg += te.series * reps * (te.cargaKg ?? 0);
    }
    final hasLoadVolume = volumeKg > 0;
    final volumeLabel =
        hasLoadVolume
            ? '${(volumeKg / 1000).toStringAsFixed(1)}t'
            : '${grouped.keys.length}';
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight + 6;
    final expandedHeight = topInset + 132;

    Future<void> openEditPrescription(TreinoExercicioItem item) async {
      HapticFeedback.selectionClick();
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.34),
        builder:
            (_) => _EditPrescriptionSheet(
              treinoId: treinoId,
              item: item,
              isDark: isDark,
              repo: repo,
            ),
      );
      if (saved != true) return;
      ref.invalidate(treinoProvider(treinoId));
      if (context.mounted) {
        FeedbackHelper.showSuccess(context, 'Prescrição atualizada.');
      }
    }

    return CustomScrollView(
      slivers: [
        // Hero AppBar
        SliverAppBar(
          expandedHeight: expandedHeight,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: isDark ? EagleTokens.darkBg : heroDeep,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 48,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _TreinoDetailBackButton(alunoId: alunoId),
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: const GradientRotation(160 * math.pi / 180),
                      colors: [heroPrimary, heroDeep],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
                CustomPaint(painter: const _GridTexturePainter()),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    TokensStrip.s5,
                    topInset,
                    20,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(17),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.18),
                                    Colors.white.withValues(alpha: 0.05),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.fitness_center_rounded,
                                size: 29,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contextLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.inter(
                                      color: Colors.white.withValues(
                                        alpha: 0.68,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    displayName,
                                    style: AppTypography.inter(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0,
                                      height: 1.02,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${treino.exercicios.length} exercício${treino.exercicios.length == 1 ? '' : 's'}',
                                    style: AppTypography.mono(
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _HeroMetricChip(
                            label: 'Duração est.',
                            value: '~${durationMin}min',
                          ),
                          const SizedBox(width: 8),
                          _HeroMetricChip(
                            label: 'Exercícios',
                            value: '${treino.exercicios.length}',
                          ),
                          const SizedBox(width: 8),
                          _HeroMetricChip(
                            label: hasLoadVolume ? 'Volume' : 'Grupos',
                            value: volumeLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 14, 20, 6),
            child: _TreinoHeroActions(
              primary: primary,
              onAdd: () {
                HapticFeedback.mediumImpact();
                context
                    .push<bool>(
                      '/treinos/$treinoId/exercicios/add',
                      extra: alunoId == null ? null : {'alunoId': alunoId},
                    )
                    .then((added) {
                      if (added == true) {
                        ref.invalidate(treinoProvider(treinoId));
                      }
                    });
              },
              onMenu: () => _openMenu(context),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 14, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercícios',
                  style: AppTypography.inter(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color:
                        isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : EagleTokens.brandSofter,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : primary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        '${treino.exercicios.length} ${treino.exercicios.length == 1 ? 'exercício' : 'exercícios'}',
                        style: AppTypography.inter(
                          color: primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    if (treino.exercicios.length > 1) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Segure e arraste para reordenar',
                        style: AppTypography.inter(
                          color:
                              isDark
                                  ? EagleTokens.darkInkMute
                                  : TokensStrip.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        if (treino.exercicios.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyExercisesState(
              isDark: isDark,
              primary: primary,
              onAdd: () {
                HapticFeedback.mediumImpact();
                context
                    .push<bool>(
                      '/treinos/$treinoId/exercicios/add',
                      extra: alunoId == null ? null : {'alunoId': alunoId},
                    )
                    .then((
                  added,
                ) {
                  if (added == true) {
                    ref.invalidate(treinoProvider(treinoId));
                  }
                });
              },
            ),
          )
        else
          _TreinoExerciseReorderList(
            exercises: orderedExercises,
            treinoId: treinoId,
            alunoId: alunoId,
            isDark: isDark,
            primary: primary,
            primarySoft: primarySoft,
            repo: repo,
            ref: ref,
            onEditPrescription: openEditPrescription,
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _TreinoExerciseReorderList extends StatefulWidget {
  final List<TreinoExercicioItem> exercises;
  final int treinoId;
  final int? alunoId;
  final bool isDark;
  final Color primary;
  final Color primarySoft;
  final TreinoRepository repo;
  final WidgetRef ref;
  final Future<void> Function(TreinoExercicioItem item) onEditPrescription;

  const _TreinoExerciseReorderList({
    required this.exercises,
    required this.treinoId,
    required this.alunoId,
    required this.isDark,
    required this.primary,
    required this.primarySoft,
    required this.repo,
    required this.ref,
    required this.onEditPrescription,
  });

  @override
  State<_TreinoExerciseReorderList> createState() =>
      _TreinoExerciseReorderListState();
}

class _TreinoExerciseReorderListState extends State<_TreinoExerciseReorderList> {
  late List<TreinoExercicioItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [...widget.exercises];
  }

  @override
  void didUpdateWidget(covariant _TreinoExerciseReorderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameOrder(oldWidget.exercises, widget.exercises)) {
      _items = [...widget.exercises];
    }
  }

  bool _sameOrder(List<TreinoExercicioItem> a, List<TreinoExercicioItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    var targetIndex = newIndex;
    if (oldIndex < targetIndex) targetIndex -= 1;
    final snapshot = [..._items];
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(targetIndex, item);
    });
    HapticFeedback.mediumImpact();
    final ids = _items.map((item) => item.id).toList();
    try {
      await widget.repo.reordenarExercicios(widget.treinoId, ids);
      widget.ref.invalidate(treinoProvider(widget.treinoId));
    } catch (error) {
      if (!mounted) return;
      setState(() => _items = snapshot);
      FeedbackHelper.showError(context, 'Erro ao reordenar: $error');
    }
  }

  Future<void> _removeExercise(TreinoExercicioItem te) async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder:
          (ctx) => _RemoveExerciseSheet(
            title: te.exercicio.nomeDisplay,
            isDark: widget.isDark,
          ),
    );
    if (confirm != true || !mounted) return;
    try {
      await widget.repo.removerExercicio(widget.treinoId, te.id);
      widget.ref.invalidate(treinoProvider(widget.treinoId));
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, 'Erro ao remover: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverReorderableList(
      itemCount: _items.length,
      onReorder: _onReorder,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = Curves.easeOut.transform(animation.value);
            return Material(
              elevation: 6 * t,
              color: Colors.transparent,
              shadowColor: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final te = _items[index];
        final showHeader = _showsExerciseGroupHeader(_items, index);
        final groupLabel = _workoutGroupLabel(te);
        final groupCount = _groupExerciseCount(_items, index);
        final isFirstInGroup = showHeader;
        final isLastInGroup = _isLastInExerciseGroup(_items, index);
        final mute =
            widget.isDark
                ? EagleTokens.darkInkMute
                : TokensStrip.textSecondary;

        final row = _ExercicioRow(
          te: te,
          index: _localIndexInGroup(_items, index),
          isDark: widget.isDark,
          primary: widget.primary,
          primarySoft: widget.primarySoft,
          isLast: isLastInGroup,
          onEditPrescription: () => widget.onEditPrescription(te),
          onDuplicate: () async {
            try {
              await widget.repo.duplicarExercicio(widget.treinoId, te.id);
              widget.ref.invalidate(treinoProvider(widget.treinoId));
            } catch (error) {
              if (mounted) {
                FeedbackHelper.showError(context, 'Erro ao duplicar: $error');
              }
            }
          },
          onSubstitute: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder:
                  (_) => SubstituirExercicioBottomSheet(
                    alvo: te.exercicio,
                    onEscolher: (novo) async {
                      try {
                        await widget.repo.substituirExercicio(
                          widget.treinoId,
                          te,
                          novo.id,
                        );
                        AnalyticsService.instance.track(
                          'substituir_uso',
                          props: {
                            'treinoId': widget.treinoId,
                            'alvoId': te.exercicio.id,
                            'novoId': novo.id,
                          },
                        );
                        widget.ref.invalidate(treinoProvider(widget.treinoId));
                      } catch (error) {
                        if (mounted) {
                          FeedbackHelper.showError(
                            context,
                            'Erro ao substituir: $error',
                          );
                        }
                      }
                    },
                    onCriarNovo: () => context.push('/exercicios/novo'),
                  ),
            );
          },
          onRemove: () => _removeExercise(te),
        );

        return ReorderableDelayedDragStartListener(
          key: ValueKey(te.id),
          index: index,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showHeader)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.primary.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          groupLabel,
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$groupCount ex.',
                          style: AppTypography.mono(
                            color: mute,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  margin: EdgeInsets.only(bottom: isLastInGroup ? 14 : 0),
                  decoration: fxListCardDecoration(
                    context,
                    accent: widget.primary,
                  ).copyWith(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(
                        isFirstInGroup ? TokensStrip.rCard : 0,
                      ),
                      bottom: Radius.circular(
                        isLastInGroup ? TokensStrip.rCard : 0,
                      ),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: row,
                ),
              ],
            ),
          ),
        );
      },
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
    final ink =
        color ?? (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary);
    final border =
        isDark
            ? Colors.white.withValues(alpha: 0.06)
            : TokensStrip.borderDefault.withValues(alpha: 0.95);
    final iconFill =
        color == null
            ? (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : EagleTokens.brandSofter)
            : EagleTokens.bad.withValues(alpha: isDark ? 0.16 : 0.10);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.035)
                    : const Color(0xFFFEFEFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow:
                isDark
                    ? null
                    : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.018),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconFill,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: ink, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.inter(
                    color: ink,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ink, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignWorkoutSheet extends StatefulWidget {
  final List<Aluno> alunos;
  final bool isDark;

  const _AssignWorkoutSheet({required this.alunos, required this.isDark});

  @override
  State<_AssignWorkoutSheet> createState() => _AssignWorkoutSheetState();
}

class _AssignWorkoutSheetState extends State<_AssignWorkoutSheet> {
  int? selectedAlunoId;

  @override
  void initState() {
    super.initState();
    selectedAlunoId = widget.alunos.isEmpty ? null : widget.alunos.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = widget.isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute =
        widget.isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final border =
        widget.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : TokensStrip.borderDefault.withValues(alpha: 0.95);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, math.max(10, bottom + 8)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: fxListCardDecoration(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:
                      widget.isDark
                          ? Colors.white.withValues(alpha: 0.16)
                          : TokensStrip.borderDefault,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: EagleTokens.brandSofter,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atribuir treino',
                          style: AppTypography.inter(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.alunos.isEmpty
                              ? 'Nenhum aluno cadastrado.'
                              : 'Escolha quem recebe este plano.',
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s4),
              if (widget.alunos.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        widget.isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : TokensStrip.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    'Cadastre um aluno antes de atribuir este treino.',
                    style: AppTypography.inter(
                      color: mute,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: widget.alunos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final aluno = widget.alunos[index];
                        final selected = selectedAlunoId == aluno.id;
                        final initials =
                            aluno.nome.trim().isEmpty
                                ? '?'
                                : aluno.nome
                                    .trim()
                                    .split(RegExp(r'\s+'))
                                    .take(2)
                                    .map((part) => part[0].toUpperCase())
                                    .join();

                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => selectedAlunoId = aluno.id);
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  selected
                                      ? EagleTokens.brandSofter
                                      : widget.isDark
                                      ? Colors.white.withValues(alpha: 0.03)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    selected
                                        ? primary.withValues(alpha: 0.28)
                                        : border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color:
                                        selected
                                            ? primary
                                            : EagleTokens.brandSofter,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initials,
                                    style: AppTypography.inter(
                                      color: selected ? Colors.white : primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        aluno.nome,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.inter(
                                          color: ink,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        aluno.objetivo?.trim().isNotEmpty ==
                                                true
                                            ? aluno.objetivo!.trim()
                                            : 'Objetivo não definido',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.inter(
                                          color: mute,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color:
                                      selected
                                          ? primary
                                          : mute.withValues(alpha: 0.7),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: TokensStrip.s4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        side: BorderSide(color: border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: ink,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          selectedAlunoId == null
                              ? null
                              : () => Navigator.pop(context, selectedAlunoId),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        backgroundColor: primary,
                        disabledBackgroundColor: primary.withValues(
                          alpha: 0.28,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: const Text('Atribuir'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreinoHeroActions extends StatelessWidget {
  final Color primary;
  final VoidCallback onAdd;
  final VoidCallback onMenu;

  const _TreinoHeroActions({
    required this.primary,
    required this.onAdd,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? EagleTokens.darkCard : TokensStrip.cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: primary.withValues(alpha: isDark ? 0.22 : 0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: isDark ? 0.10 : 0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: primary,
                      size: 19,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Adicionar exercício',
                      style: AppTypography.inter(
                        color: primary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onMenu,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : TokensStrip.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: primary.withValues(alpha: isDark ? 0.18 : 0.12),
                ),
              ),
              child: Icon(
                Icons.more_horiz_rounded,
                color: isDark ? Colors.white : primary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroMetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.mono(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
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
  final VoidCallback onDuplicate;
  final VoidCallback onSubstitute;
  final VoidCallback onRemove;
  final VoidCallback onEditPrescription;

  const _ExercicioRow({
    required this.te,
    required this.index,
    required this.isDark,
    required this.primary,
    required this.primarySoft,
    required this.isLast,
    required this.onDuplicate,
    required this.onSubstitute,
    required this.onRemove,
    required this.onEditPrescription,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final isAdvanced = te.tipoSerie != 'NORMAL';
    final trustColor = _trustColor(te.exercicio, primary);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        border:
            isLast ? null : Border(bottom: BorderSide(color: line, width: 0.5)),
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Segure para reordenar ${te.exercicio.nomeDisplay}',
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 20,
                color: mute.withValues(alpha: 0.72),
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: primary.withValues(alpha: 0.10)),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: AppTypography.mono(
                color: primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onEditPrescription,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        te.exercicio.nomeDisplay,
                  style: AppTypography.inter(
                    color: ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${te.series}×${te.repeticoes}',
                      style: AppTypography.mono(
                        color: ink,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w700,
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
                      _formatLoadKg(te.cargaKg),
                      style: AppTypography.mono(
                        color: ink,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w700,
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
                      style: AppTypography.mono(
                        color: mute,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (isAdvanced ||
                    te.exercicio.showMediaBadgeInWorkoutList ||
                    te.observacoes?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (te.exercicio.showMediaBadgeInWorkoutList)
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
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              HapticFeedback.selectionClick();
              final action = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.black.withValues(alpha: 0.34),
                builder:
                    (_) => _ExerciseActionsSheet(
                      title: te.exercicio.nomeDisplay,
                      isDark: isDark,
                    ),
              );
              if (action == 'edit') onEditPrescription();
              if (action == 'duplicate') onDuplicate();
              if (action == 'substitute') onSubstitute();
              if (action == 'remove') onRemove();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : TokensStrip.borderDefault,
                ),
              ),
              child: Icon(Icons.more_vert_rounded, color: mute, size: 18),
            ),
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
            style: AppTypography.inter(
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

class _ExerciseActionsSheet extends StatelessWidget {
  final String title;
  final bool isDark;

  const _ExerciseActionsSheet({
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final border =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : TokensStrip.borderDefault.withValues(alpha: 0.9);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: fxListCardDecoration(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : EagleTokens.brandSofter,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ações do exercício',
                          style: AppTypography.inter(
                            color: ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s4),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ExerciseActionTile(
                        icon: Icons.edit_note_rounded,
                        label: 'Editar prescrição',
                        onTap: () => Navigator.pop(context, 'edit'),
                      ),
                      _ExerciseActionTile(
                        icon: Icons.copy_rounded,
                        label: 'Duplicar item',
                        onTap: () => Navigator.pop(context, 'duplicate'),
                      ),
                      _ExerciseActionTile(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Substituir exercício',
                        onTap: () => Navigator.pop(context, 'substitute'),
                      ),
                      _ExerciseActionTile(
                        icon: Icons.remove_circle_outline_rounded,
                        label: 'Remover do treino',
                        color: EagleTokens.bad,
                        onTap: () => Navigator.pop(context, 'remove'),
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
}

class _ExerciseActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ExerciseActionTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink =
        color ?? (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary);
    final border =
        isDark
            ? Colors.white.withValues(alpha: 0.06)
            : TokensStrip.borderDefault.withValues(alpha: 0.95);
    final iconFill =
        color == null
            ? (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : EagleTokens.brandSofter)
            : EagleTokens.bad.withValues(alpha: isDark ? 0.16 : 0.10);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.035)
                    : const Color(0xFFFEFEFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconFill,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: ink, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.inter(
                    color: ink,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ink, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoveExerciseSheet extends StatelessWidget {
  final String title;
  final bool isDark;

  const _RemoveExerciseSheet({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final border =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : TokensStrip.borderDefault.withValues(alpha: 0.9);
    final dangerFill =
        isDark ? const Color(0xFFB24646) : const Color(0xFFA83A3A);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: fxListCardDecoration(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: EagleTokens.bad.withValues(
                        alpha: isDark ? 0.16 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: EagleTokens.bad,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remover exercício?',
                          style: AppTypography.inter(
                            color: ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$title sai apenas deste treino. O exercício continua disponível na biblioteca.',
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: 13,
                            height: 1.38,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: ink,
                        side: BorderSide(color: border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: AppTypography.inter(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: dangerFill,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Remover',
                        style: AppTypography.inter(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteTrainingSheet extends StatelessWidget {
  final String title;
  final bool isDark;

  const _DeleteTrainingSheet({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final border =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : TokensStrip.borderDefault.withValues(alpha: 0.9);
    final softBad = EagleTokens.bad.withValues(alpha: isDark ? 0.18 : 0.1);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: fxListCardDecoration(context, accent: primary),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: softBad,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: EagleTokens.bad,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remover treino?',
                          style: AppTypography.inter(
                            color: ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$title sai da biblioteca. Históricos já concluídos continuam preservados.',
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: 13,
                            height: 1.38,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : EagleTokens.brandSoft.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: isDark ? EagleTokens.darkInkMute : primary,
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Execuções antigas e dados de alunos não serão apagados.',
                        style: AppTypography.inter(
                          color: mute,
                          fontSize: 12.5,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: ink,
                        side: BorderSide(color: border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: EagleTokens.bad,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Remover'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

class _DetailErrorState extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _DetailErrorState({
    required this.isDark,
    required this.primary,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: EagleTokens.bad.withValues(
                    alpha: isDark ? 0.16 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: EagleTokens.bad,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Falha ao carregar treino',
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  color: ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verifique a conexão e tente novamente. Se o problema persistir, volte e reabra.',
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  color: mute,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Voltar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ink,
                      side: BorderSide(color: line),
                      minimumSize: const Size(120, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FxLiquidPrimaryButton(
                      label: 'Tentar novamente',
                      icon: Icons.refresh_rounded,
                      onPressed: onRetry,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyExercisesState extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final VoidCallback onAdd;

  const _EmptyExercisesState({
    required this.isDark,
    required this.primary,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: BrandPalette.soft(primary, dark: isDark),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
            child: Icon(Icons.fitness_center_rounded, color: primary, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            'Nenhum exercício ainda',
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              color: ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione exercícios da biblioteca curada para montar este treino.',
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              color: mute,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 260,
            child: FxLiquidPrimaryButton(
              label: 'Adicionar exercício',
              icon: Icons.add_rounded,
              onPressed: onAdd,
              expand: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditPrescriptionSheet extends StatefulWidget {
  const _EditPrescriptionSheet({
    required this.treinoId,
    required this.item,
    required this.isDark,
    required this.repo,
  });

  final int treinoId;
  final TreinoExercicioItem item;
  final bool isDark;
  final TreinoRepository repo;

  @override
  State<_EditPrescriptionSheet> createState() => _EditPrescriptionSheetState();
}

class _EditPrescriptionSheetState extends State<_EditPrescriptionSheet> {
  late final TextEditingController _seriesCtrl;
  late final TextEditingController _repCtrl;
  late final TextEditingController _descansoCtrl;
  late final TextEditingController _cargaCtrl;
  late final TextEditingController _obsCtrl;
  late final TextEditingController _supersetCtrl;
  late String _tipoSerie;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _seriesCtrl = TextEditingController(text: '${item.series}');
    _repCtrl = TextEditingController(text: item.repeticoes);
    _descansoCtrl = TextEditingController(
      text: '${item.descansoSegundos ?? 60}',
    );
    _cargaCtrl = TextEditingController(
      text:
          item.cargaKg != null && item.cargaKg! > 0
              ? item.cargaKg!.toString()
              : '',
    );
    _obsCtrl = TextEditingController(text: item.observacoes ?? '');
    _supersetCtrl = TextEditingController(
      text: '${item.grupoSuperset ?? 1}',
    );
    _tipoSerie = item.tipoSerie;
  }

  @override
  void dispose() {
    _seriesCtrl.dispose();
    _repCtrl.dispose();
    _descansoCtrl.dispose();
    _cargaCtrl.dispose();
    _obsCtrl.dispose();
    _supersetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.repo.atualizarExercicioPrescricao(
        widget.treinoId,
        widget.item.id,
        series: int.tryParse(_seriesCtrl.text) ?? widget.item.series,
        repeticoes: _repCtrl.text.trim(),
        descansoSegundos: int.tryParse(_descansoCtrl.text) ?? 60,
        cargaKg: double.tryParse(_cargaCtrl.text.replaceAll(',', '.')),
        observacoes: _obsCtrl.text,
        tipoSerie: _tipoSerie,
        grupoSuperset:
            _tipoSerie == 'SUPERSET'
                ? int.tryParse(_supersetCtrl.text)
                : null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, Color primary) {
    final radius = BorderRadius.circular(14);
    return InputDecoration(
      labelText: label,
      border: FxInputDeco.outlineBorder(borderRadius: radius),
      enabledBorder: FxInputDeco.outlineBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: primary.withValues(alpha: 0.22)),
      ),
      focusedBorder: FxInputDeco.outlineBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: primary, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = widget.isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute =
        widget.isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: fxListCardDecoration(context, accent: primary),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: mute.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Editar prescrição',
                  style: AppTypography.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.exercicio.nomeDisplay,
                  style: AppTypography.inter(
                    color: mute,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _seriesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _decoration('Séries', primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _repCtrl,
                        decoration: _decoration('Repetições', primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _descansoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _decoration('Descanso (s)', primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _cargaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration('Carga (kg)', primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _tipoSerie,
                  decoration: _decoration('Tipo de série', primary),
                  items: const [
                    DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                    DropdownMenuItem(
                      value: 'SUPERSET',
                      child: Text('Superset'),
                    ),
                    DropdownMenuItem(
                      value: 'DROPSET',
                      child: Text('Drop set'),
                    ),
                  ],
                  onChanged:
                      _saving
                          ? null
                          : (value) {
                            if (value == null) return;
                            setState(() => _tipoSerie = value);
                          },
                ),
                if (_tipoSerie == 'SUPERSET') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _supersetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _decoration('Grupo superset', primary),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _obsCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: _decoration('Observações', primary),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: primary,
                  ),
                  child:
                      _saving
                          ? const FxLoading(
                            size: 22,
                            strokeWidth: 2,
                            color: Colors.white,
                          )
                          : const Text('Salvar prescrição'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
