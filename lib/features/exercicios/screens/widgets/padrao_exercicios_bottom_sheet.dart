import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_home_sheet.dart';
import '../../../treinos/utils/exercise_picker_sort.dart';
import '../../data/enums.dart';
import '../../data/exercicio_repository.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../providers/exercicios_provider.dart';
import '../../../treinos/utils/exercise_picker_filter.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import 'exercise_media_thumb.dart';
import 'exercise_video_preview_sheet.dart';

class PadraoExerciciosBottomSheet extends ConsumerWidget {
  const PadraoExerciciosBottomSheet({
    super.key,
    this.padrao,
    this.grupo,
    required this.onAdicionar,
    this.alreadyInTreinoIds = const {},
    this.pickerFilter = const ExercisePickerFilter(),
  });

  final PadraoMovimento? padrao;
  final GrupoMuscular? grupo;
  final ValueChanged<Exercicio> onAdicionar;
  final Set<int> alreadyInTreinoIds;
  final ExercisePickerFilter pickerFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(exerciciosProvider);
    final title =
        padrao != null
            ? TaxonomyLabels.padrao[padrao!] ?? 'Padrão'
            : TaxonomyLabels.grupo[grupo!] ?? 'Grupo';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final scheme = Theme.of(context).colorScheme;
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        FxHomeSheetChrome.expandHeightFactor;

    Widget header({int count = 0}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: title,
            subtitle: 'Toque para revisar a prescrição e adicionar ao treino.',
            leading: Icon(
              Icons.fitness_center_outlined,
              color: primary,
              size: 18,
            ),
            trailing: Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count exercícios',
                style: AppTypography.inter(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return FxHomeSheetSurface(
      isDark: isDark,
      expand: true,
      maxHeight: maxHeight,
      child: asyncList.when(
        loading:
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header(),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder:
                        (_, __) => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SkeletonLoader(
                                width: 44,
                                height: 44,
                                borderRadius: 14,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SkeletonLoader(height: 14, borderRadius: 8),
                                    SizedBox(height: 8),
                                    SkeletonLoader(
                                      height: 11,
                                      width: 120,
                                      borderRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              ],
            ),
        error:
            (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header(),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Não foi possível carregar os exercícios.',
                        textAlign: TextAlign.center,
                        style: AppTypography.inter(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        data: (all) {
          final filtered = applyExercisePickerFilter(all, pickerFilter);
          final items = sortExerciciosForPicker(
            filtered.where((ex) {
              if (padrao != null) {
                return ex.padraoMovimento == padrao;
              }
              if (grupo != null) {
                return ex.grupoMuscularPrimario == grupo;
              }
              return false;
            }),
            alreadyInTreinoIds: alreadyInTreinoIds,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header(count: items.length),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder:
                      (context, index) => Divider(
                        height: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                  itemBuilder: (context, index) {
                    final ex = items[index];
                    final subtitle = [
                      if (ex.grupoMuscularPrimario != null)
                        TaxonomyLabels.grupo[ex.grupoMuscularPrimario!],
                      if (ex.equipamentos.isNotEmpty)
                        ex.equipamentos
                            .take(2)
                            .map((e) => TaxonomyLabels.equipamento[e])
                            .whereType<String>()
                            .join(' / '),
                    ].whereType<String>().join(' · ');
                    return _ExerciseChoiceTile(
                      exercicio: ex,
                      subtitle: subtitle,
                      alreadyInTreino: alreadyInTreinoIds.contains(ex.id),
                      onPreview:
                          ex.hasPlayableMedia
                              ? () => showExerciseMediaPreview(
                                context,
                                exercicio: ex,
                              )
                              : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                        onAdicionar(ex);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExerciseChoiceTile extends StatelessWidget {
  final Exercicio exercicio;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onPreview;
  final bool alreadyInTreino;

  const _ExerciseChoiceTile({
    required this.exercicio,
    required this.subtitle,
    required this.onTap,
    this.onPreview,
    this.alreadyInTreino = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nome = exercicio.nomeDisplay;
    final muted = alreadyInTreino;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            GestureDetector(
              onTap:
                  onPreview == null
                      ? null
                      : () {
                        HapticFeedback.selectionClick();
                        onPreview!();
                      },
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
                  Text(
                    nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: muted ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                  if (alreadyInTreino) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Já está neste treino',
                      style: AppTypography.inter(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add_rounded, color: scheme.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
