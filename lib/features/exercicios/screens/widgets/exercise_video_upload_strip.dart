import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_motion.dart';
import '../../../../core/widgets/fx_shell_scaffold.dart';
import '../../data/exercicio_repository.dart';
import 'exercise_media_thumb.dart';

enum ExerciseVideoUploadAction { preview, upload, remove }

/// Barra compacta para enviar/trocar vídeo do personal em qualquer fluxo.
class ExerciseVideoUploadStrip extends StatelessWidget {
  const ExerciseVideoUploadStrip({
    super.key,
    required this.exercicio,
    required this.isDark,
    required this.primary,
    required this.mediaLoading,
    required this.onPreview,
    required this.onUpload,
    required this.onRemove,
    this.dense = false,
  });

  final Exercicio exercicio;
  final bool isDark;
  final Color primary;
  final bool mediaLoading;
  final VoidCallback onPreview;
  final VoidCallback onUpload;
  final VoidCallback onRemove;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final hasPersonalVideo = exercicioHasPersonalVideo(exercicio);
    final hasLibraryDemo =
        exercicio.hasPlayableMedia && !hasPersonalVideo;
    final hasAnyMedia = hasPersonalVideo || hasLibraryDemo;
    final statusColor =
        hasAnyMedia
            ? primary
            : isDark
            ? Colors.white.withValues(alpha: 0.68)
            : TokensStrip.textSecondary;
    final statusIcon =
        mediaLoading
            ? Icons.hourglass_empty_rounded
            : hasPersonalVideo
            ? Icons.play_circle_fill_rounded
            : hasLibraryDemo
            ? Icons.video_library_rounded
            : Icons.video_call_outlined;
    final statusTitle =
        mediaLoading
            ? 'Processando vídeo'
            : hasPersonalVideo
            ? 'Vídeo próprio disponível'
            : hasLibraryDemo
            ? 'Demonstração da biblioteca'
            : 'Sem demonstração';
    final statusSubtitle =
        hasPersonalVideo
            ? 'Confira a prévia ou troque seu vídeo.'
            : hasLibraryDemo
            ? 'Assista a demo ou envie seu próprio vídeo.'
            : 'Envie sua demonstração antes de prescrever.';

    return Container(
      padding: EdgeInsets.fromLTRB(12, dense ? 8 : 10, 8, dense ? 8 : 10),
      decoration: fxListCardDecoration(
        context,
        accent: hasAnyMedia ? primary : null,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    color: mute,
                    fontSize: 11.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (hasAnyMedia)
            TextButton(
              onPressed: mediaLoading ? null : onPreview,
              style: TextButton.styleFrom(
                foregroundColor: primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: const Text('Prévia'),
            ),
          if (hasPersonalVideo)
            PopupMenuButton<ExerciseVideoUploadAction>(
              enabled: !mediaLoading,
              tooltip: 'Ações de vídeo',
              icon: Icon(Icons.more_horiz_rounded, color: mute),
              onSelected: (action) {
                if (action == ExerciseVideoUploadAction.preview) onPreview();
                if (action == ExerciseVideoUploadAction.upload) onUpload();
                if (action == ExerciseVideoUploadAction.remove) onRemove();
              },
              itemBuilder:
                  (context) => const [
                    PopupMenuItem(
                      value: ExerciseVideoUploadAction.preview,
                      child: Text('Ver prévia'),
                    ),
                    PopupMenuItem(
                      value: ExerciseVideoUploadAction.upload,
                      child: Text('Trocar vídeo'),
                    ),
                    PopupMenuItem(
                      value: ExerciseVideoUploadAction.remove,
                      child: Text('Remover vídeo'),
                    ),
                  ],
            )
          else ...[
            if (hasLibraryDemo)
              TextButton(
                onPressed: mediaLoading ? null : onPreview,
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  textStyle: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('Demo'),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: FxLiquidPrimaryButton(
                label: hasLibraryDemo ? 'Meu vídeo' : 'Enviar vídeo',
                onPressed: mediaLoading ? null : onUpload,
                loading: mediaLoading,
                expand: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
