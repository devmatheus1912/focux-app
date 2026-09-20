import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/fx_shell_scaffold.dart';
import '../../../../core/utils/friendly_error.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../data/enums.dart';
import '../../data/exercicio_repository.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../providers/exercicios_provider.dart';
import 'exercise_media_thumb.dart';

class ExercicioCard extends ConsumerWidget {
  final Exercicio exercicio;
  final VoidCallback onFavoritoToggle;
  final VoidCallback onUploadVideo;
  final VoidCallback onDelete;
  final VoidCallback? onTapOverride;
  final VoidCallback? onLongPress;
  final bool selected;
  final Color? accent;

  const ExercicioCard({
    super.key,
    required this.exercicio,
    required this.onFavoritoToggle,
    required this.onUploadVideo,
    required this.onDelete,
    this.onTapOverride,
    this.onLongPress,
    this.selected = false,
    this.accent,
  });

  Future<void> _toggleFavorito(WidgetRef ref, BuildContext context) async {
    final repo = ref.read(exercicioRepositoryProvider);
    try {
      if (exercicio.favoritado) {
        await repo.desfavoritarExercicio(exercicio.id);
      } else {
        await repo.favoritarExercicio(exercicio.id);
      }
      onFavoritoToggle();
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = accent ?? Theme.of(context).colorScheme.primary;
    final mute = Theme.of(context).colorScheme.onSurfaceVariant;
    final hasPersonalVideo = exercicioHasPersonalVideo(exercicio);
    final hasDemo = exercicio.hasPlayableMedia;
    final subtitle = [
      _grupoLabel(exercicio),
      _equipamentoLabel(exercicio),
      hasPersonalVideo
          ? 'Vídeo próprio'
          : hasDemo
          ? 'Biblioteca'
          : 'Sem demo',
    ].where((s) => s != null && s.isNotEmpty).join(' · ');

    return GestureDetector(
      onLongPress: onLongPress,
      child: FxSatelliteListTile(
      title: exercicio.nome,
      accent: primary,
      titleCase: false,
      onTap:
          onTapOverride ?? () => context.push('/exercicios/${exercicio.id}'),
      leading: Icon(
        Icons.fitness_center_rounded,
        color: primary,
        size: 20,
      ),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (exercicio.hasPlayableMedia)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: ExerciseMediaThumb.fromExercicio(
                exercicio,
                size: 28,
              ),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            iconSize: 20,
            icon: Icon(
              exercicio.favoritado ? Icons.star : Icons.star_border,
              color:
                  exercicio.favoritado ? EagleTokens.gold : mute,
            ),
            tooltip:
                exercicio.favoritado
                    ? 'Remover dos favoritos'
                    : 'Adicionar aos favoritos',
            onPressed: () => _toggleFavorito(ref, context),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded, color: primary, size: 20)
          else
            PopupMenuButton<String>(
              tooltip: 'Acoes do exercicio',
              padding: EdgeInsets.zero,
              splashRadius: 18,
              offset: const Offset(0, 36),
              position: PopupMenuPosition.under,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(Icons.more_vert_rounded, color: mute, size: 20),
              onSelected: (value) {
                if (value == 'video') onUploadVideo();
                if (value == 'delete') onDelete();
              },
              itemBuilder:
                  (_) => [
                    PopupMenuItem(
                      value: 'video',
                      child: Row(
                        children: [
                          Icon(
                            hasPersonalVideo
                                ? Icons.swap_horiz_rounded
                                : Icons.upload_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            hasPersonalVideo
                                ? 'Trocar vídeo'
                                : hasDemo
                                ? 'Enviar meu vídeo'
                                : 'Subir vídeo',
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: EagleTokens.bad,
                          ),
                          SizedBox(width: 10),
                          Text('Excluir'),
                        ],
                      ),
                    ),
                  ],
            ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 6),
      ),
    );
  }
}

String? _grupoLabel(Exercicio exercicio) {
  final grupo = exercicio.grupoMuscularPrimario;
  if (grupo != null) return TaxonomyLabels.grupo[grupo];
  return exercicio.musculoAlvo;
}

String? _equipamentoLabel(Exercicio exercicio) {
  if (exercicio.equipamentos.isNotEmpty) {
    return exercicio.equipamentos
        .take(2)
        .map((e) => TaxonomyLabels.equipamento[e] ?? e.backendName)
        .join(' / ');
  }
  return exercicio.equipamento;
}
