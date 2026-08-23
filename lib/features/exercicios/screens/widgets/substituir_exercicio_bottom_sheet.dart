import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_home_sheet.dart';
import '../../../../core/widgets/fx_loading.dart';
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
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return FxHomeSheetSurface(
      isDark: isDark,
      expand: true,
      maxHeight:
          MediaQuery.sizeOf(context).height *
          FxHomeSheetChrome.expandHeightFactor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Trocar por similar',
            subtitle: 'Substituindo ${alvo.nomeDisplay}',
            leading: Icon(Icons.swap_horiz_rounded, color: primary, size: 18),
          ),
          Expanded(
            child: asyncList.when(
              loading:
                  () => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FxLoading.sectionShimmer(context, height: 180),
                  ),
              error:
                  (_, __) => Center(
                    child: Text(
                      'Não foi possível buscar alternativas.',
                      style: FocuxHubTypography.bodyMuted(color: mute),
                    ),
                  ),
              data: (todos) {
                final alternativas = SubstituicaoEngine().encontrarAlternativas(
                  alvo: alvo,
                  candidatos: todos,
                  equipamentosAluno: equipamentosAluno,
                );

                return Column(
                  children: [
                    if (alternativas.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${alternativas.length} opções por padrão de movimento e equipamento',
                            style: FocuxHubTypography.bodyMuted(
                              color: primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child:
                          alternativas.isEmpty
                              ? _EmptyState(
                                onCriarNovo:
                                    onCriarNovo == null
                                        ? null
                                        : () {
                                          Navigator.of(context).pop();
                                          onCriarNovo!();
                                        },
                              )
                              : ListView.separated(
                                padding: const EdgeInsets.only(bottom: 8),
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
                        padding: const EdgeInsets.only(top: 8),
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
        ],
      ),
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
                            style: FocuxHubTypography.cardTitle(
                              color: ink,
                            ).copyWith(fontWeight: FontWeight.w900),
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
                        style: FocuxHubTypography.bodyMuted(
                          color: mute,
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
        style: FocuxHubTypography.chip(primary),
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
          style: FocuxHubTypography.bodyMuted(
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
