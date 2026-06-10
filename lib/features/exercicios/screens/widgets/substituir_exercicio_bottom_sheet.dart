import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_loading.dart';
import '../../../../core/widgets/fx_shell_scaffold.dart';
import '../../data/enums.dart';
import '../../data/exercicio_repository.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../data/substituicao_engine.dart';
import '../../providers/exercicios_provider.dart';
import 'exercise_media_thumb.dart';
import 'exercise_video_preview_sheet.dart';

class SubstituirExercicioBottomSheet extends ConsumerWidget {
  const SubstituirExercicioBottomSheet({
    super.key,
    required this.alvo,
    required this.onEscolher,
    this.equipamentosAluno,
    this.onCriarNovo,
  });

  final Exercicio alvo;
  final Set<Equipamento>? equipamentosAluno;
  final ValueChanged<Exercicio> onEscolher;
  final VoidCallback? onCriarNovo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(exerciciosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Container(
              decoration: fxListCardDecoration(context, accent: primary),
              child: asyncList.when(
                loading:
                    () => const SizedBox(
                      height: 220,
                      child: Center(child: FxLoading()),
                    ),
                error:
                    (_, __) => SizedBox(
                      height: 220,
                      child: Center(
                        child: Text(
                          'Não foi possível buscar alternativas.',
                          style: AppTypography.inter(color: mute),
                        ),
                      ),
                    ),
                data: (todos) {
                  final alternativas = SubstituicaoEngine()
                      .encontrarAlternativas(
                        alvo: alvo,
                        candidatos: todos,
                        equipamentosAluno: equipamentosAluno,
                      );

                  return Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: mute.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trocar por similar',
                              style: AppTypography.inter(
                                color: ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Substituindo ${alvo.nomeDisplay}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.inter(
                                color: mute,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (alternativas.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${alternativas.length} opções por padrão de movimento e equipamento',
                                style: AppTypography.inter(
                                  color: primary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        child:
                            alternativas.isEmpty
                                ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  child: _EmptyState(
                                    onCriarNovo:
                                        onCriarNovo == null
                                            ? null
                                            : () {
                                              Navigator.of(context).pop();
                                              onCriarNovo!();
                                            },
                                  ),
                                )
                                : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    0,
                                    14,
                                    16,
                                  ),
                                  itemCount: alternativas.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final item = alternativas[index];
                                    return _AlternativaTile(
                                      item: item,
                                      primary: primary,
                                      isDark: isDark,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        Navigator.of(context).pop();
                                        onEscolher(item.exercicio);
                                      },
                                    );
                                  },
                                ),
                      ),
                      if (alternativas.isNotEmpty && onCriarNovo != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onCriarNovo!();
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Criar exercício personalizado'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AlternativaTile extends StatelessWidget {
  const _AlternativaTile({
    required this.item,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final AlternativaResultado item;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final exercicio = item.exercicio;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final meta = _metaParts(exercicio);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? EagleTokens.darkCardHi : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: line.withValues(alpha: 0.9)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap:
                    exercicio.hasPlayableMedia
                        ? () {
                          HapticFeedback.selectionClick();
                          showExerciseMediaPreview(
                            context,
                            exercicio: exercicio,
                          );
                        }
                        : null,
                child: ExerciseMediaThumb.fromExercicio(
                  exercicio,
                  size: 44,
                  radius: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            exercicio.nomeDisplay,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.inter(
                              color: ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MatchBadge(score: item.score, primary: primary),
                      ],
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          color: mute,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Icon(Icons.chevron_right_rounded, color: mute, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _metaParts(Exercicio exercicio) {
    final parts = <String>[];
    if (exercicio.padraoMovimento != null) {
      final label = TaxonomyLabels.padrao[exercicio.padraoMovimento!];
      if (label != null) parts.add(label);
    }
    if (exercicio.grupoMuscularPrimario != null) {
      final label = TaxonomyLabels.grupo[exercicio.grupoMuscularPrimario!];
      if (label != null) parts.add(label);
    }
    if (exercicio.equipamentos.isNotEmpty) {
      final label = TaxonomyLabels.equipamento[exercicio.equipamentos.first];
      if (label != null) parts.add(label);
    }
    if (exercicio.dificuldade != null) {
      final label = TaxonomyLabels.dificuldade[exercicio.dificuldade!];
      if (label != null) parts.add(label);
    }
    return parts.take(4).join(' · ');
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.score, required this.primary});

  final int score;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withValues(alpha: 0.22)),
      ),
      child: Text(
        '$clamped%',
        style: AppTypography.inter(
          color: primary,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onCriarNovo});

  final VoidCallback? onCriarNovo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.swap_horiz_rounded,
          size: 36,
          color: EagleTokens.inkMute,
        ),
        const SizedBox(height: 12),
        Text(
          'Nenhuma alternativa próxima encontrada.',
          textAlign: TextAlign.center,
          style: AppTypography.inter(
            color: EagleTokens.inkMute,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ajuste os filtros do aluno ou crie um exercício personalizado.',
          textAlign: TextAlign.center,
          style: TextStyle(color: EagleTokens.inkMute, fontSize: 12.5),
        ),
        if (onCriarNovo != null) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onCriarNovo,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Criar exercício personalizado'),
          ),
        ],
      ],
    );
  }
}
