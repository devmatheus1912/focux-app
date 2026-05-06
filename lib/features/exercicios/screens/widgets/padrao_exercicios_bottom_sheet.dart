import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/enums.dart';
import '../../data/exercicio_repository.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../providers/exercicios_provider.dart';

class PadraoExerciciosBottomSheet extends ConsumerWidget {
  const PadraoExerciciosBottomSheet({
    super.key,
    this.padrao,
    this.grupo,
    required this.onAdicionar,
  });

  final PadraoMovimento? padrao;
  final GrupoMuscular? grupo;
  final ValueChanged<Exercicio> onAdicionar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(exerciciosProvider);
    final title =
        padrao != null
            ? TaxonomyLabels.padrao[padrao!] ?? 'Padrão'
            : TaxonomyLabels.grupo[grupo!] ?? 'Grupo';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        final scheme = Theme.of(context).colorScheme;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 32,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: asyncList.when(
            loading:
                () => const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                ),
            error:
                (e, _) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Não foi possível carregar os exercícios.'),
                  ),
                ),
            data: (all) {
              final items =
                  all.where((ex) {
                      if (padrao != null) return ex.padraoMovimento == padrao;
                      if (grupo != null)
                        return ex.grupoMuscularPrimario == grupo;
                      return false;
                    }).toList()
                    ..sort((a, b) {
                      final video = (b.hasPlayableMedia ? 1 : 0).compareTo(
                        a.hasPlayableMedia ? 1 : 0,
                      );
                      if (video != 0) return video;
                      return a.nome.compareTo(b.nome);
                    });

              return ListView.separated(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  18,
                  10,
                  18,
                  MediaQuery.paddingOf(context).bottom + 18,
                ),
                itemCount: items.length + 1,
                separatorBuilder:
                    (context, index) =>
                        index == 0
                            ? const SizedBox(height: 10)
                            : Divider(
                              height: 1,
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _SheetHeader(title: title, count: items.length);
                  }
                  final ex = items[index - 1];
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
                    onTap: () {
                      Navigator.pop(context);
                      onAdicionar(ex);
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SheetHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count exercícios',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Toque em um item para usar nesta prescrição.',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ExerciseChoiceTile extends StatelessWidget {
  final Exercicio exercicio;
  final String subtitle;
  final VoidCallback onTap;

  const _ExerciseChoiceTile({
    required this.exercicio,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color:
                    exercicio.hasPlayableMedia
                        ? scheme.primary.withValues(alpha: 0.1)
                        : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                exercicio.hasPlayableMedia
                    ? Icons.play_circle_fill_rounded
                    : Icons.videocam_off_outlined,
                color:
                    exercicio.hasPlayableMedia
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercicio.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Adicionar',
              style: TextStyle(
                color: scheme.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
