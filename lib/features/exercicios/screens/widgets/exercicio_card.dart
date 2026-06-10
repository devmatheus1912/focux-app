import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/fx_shell_scaffold.dart';
import '../../data/enums.dart';
import '../../data/exercicio_repository.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../providers/exercicios_provider.dart';
import 'exercise_media_thumb.dart';
import '../../../../core/utils/friendly_error.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

class ExercicioCard extends ConsumerWidget {
  final Exercicio exercicio;
  final VoidCallback onFavoritoToggle;
  final VoidCallback onUploadVideo;
  final VoidCallback onDelete;
  final VoidCallback? onTapOverride;
  final VoidCallback? onLongPress;
  final bool selected;

  const ExercicioCard({
    super.key,
    required this.exercicio,
    required this.onFavoritoToggle,
    required this.onUploadVideo,
    required this.onDelete,
    this.onTapOverride,
    this.onLongPress,
    this.selected = false,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final subtitle = [
      _grupoLabel(exercicio),
      _equipamentoLabel(exercicio),
      _dificuldadeLabel(exercicio),
    ].where((s) => s != null && s.isNotEmpty).join(' | ');
    final hasPersonalVideo = exercicioHasPersonalVideo(exercicio);
    final hasDemo = exercicio.hasPlayableMedia;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            onTapOverride ?? () => context.push('/exercicios/${exercicio.id}'),
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: fxListCardDecoration(
            context,
            accent: primary,
            radius: 16,
            selected: selected,
          ),
          child: Row(
            children: [
              ExerciseMediaThumb.fromExercicio(
                exercicio,
                size: 54,
                radius: 14,
                iconSize: 22,
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
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: mute, fontSize: 12.5),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _MiniMediaBadge(
                          icon:
                              hasPersonalVideo
                                  ? Icons.play_circle_fill_rounded
                                  : hasDemo
                                  ? Icons.video_library_rounded
                                  : Icons.videocam_off_rounded,
                          label:
                              hasPersonalVideo
                                  ? 'Vídeo próprio'
                                  : hasDemo
                                  ? 'Biblioteca'
                                  : 'Sem demo',
                          color:
                              hasDemo
                                  ? EagleTokens.good
                                  : EagleTokens.warn,
                        ),
                        const SizedBox(width: 6),
                        if (_modalidadeLabel(exercicio)?.isNotEmpty == true)
                          Flexible(
                            child: Text(
                              _modalidadeLabel(exercicio)!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: mute,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  exercicio.favoritado ? Icons.star : Icons.star_border,
                  color:
                      exercicio.favoritado
                          ? EagleTokens.gold
                          : (isDark
                              ? EagleTokens.darkInkMute
                              : EagleTokens.inkMute),
                ),
                tooltip:
                    exercicio.favoritado
                        ? 'Remover dos favoritos'
                        : 'Adicionar aos favoritos',
                onPressed: () => _toggleFavorito(ref, context),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
              else
                PopupMenuButton<String>(
                  tooltip: 'Acoes do exercicio',
                  icon: Icon(Icons.more_vert_rounded, color: mute),
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
        ),
      ),
    );
  }
}

class _MiniMediaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniMediaBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String? _modalidadeLabel(Exercicio exercicio) {
  final modalidade = exercicio.modalidade;
  if (modalidade != null) return TaxonomyLabels.modalidade[modalidade];
  return exercicio.categoria;
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

String? _dificuldadeLabel(Exercicio exercicio) {
  final dificuldade = exercicio.dificuldade;
  if (dificuldade != null) return TaxonomyLabels.dificuldade[dificuldade];
  return exercicio.nivel;
}
