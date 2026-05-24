import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_motion.dart';
import '../../../../core/widgets/fx_shell_scaffold.dart';
import '../../data/exercicio_repository.dart';
import '../../services/biblioteca_sync_status.dart';
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
    return ListenableBuilder(
      listenable: BibliotecaSyncStatus.instance,
      builder: (context, _) {
        final sync = BibliotecaSyncStatus.instance;
        final librarySyncing =
            sync.syncing &&
            !exercicioHasPublishedLibraryMedia(exercicio) &&
            !exercicioHasPersonalVideo(exercicio);

        return _buildContent(context, librarySyncing: librarySyncing);
      },
    );
  }

  Widget _buildContent(BuildContext context, {required bool librarySyncing}) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final hasPersonalVideo = exercicioHasPersonalVideo(exercicio);
    final hasLibraryDemo =
        exercicio.hasPlayableMedia && !hasPersonalVideo;
    final hasAnyMedia = hasPersonalVideo || hasLibraryDemo;
    final statusColor =
        hasAnyMedia || librarySyncing
            ? primary
            : isDark
            ? Colors.white.withValues(alpha: 0.68)
            : TokensStrip.textSecondary;
    final statusIcon =
        mediaLoading
            ? Icons.hourglass_top_rounded
            : librarySyncing
            ? Icons.cloud_sync_rounded
            : hasPersonalVideo
            ? Icons.play_circle_fill_rounded
            : hasLibraryDemo
            ? Icons.video_library_rounded
            : Icons.video_call_outlined;
    final statusTitle =
        mediaLoading
            ? 'Enviando vídeo...'
            : librarySyncing
            ? 'Sincronizando demonstração'
            : hasPersonalVideo
            ? 'Vídeo próprio disponível'
            : hasLibraryDemo
            ? 'Demonstração da biblioteca'
            : 'Sem demonstração';
    final statusSubtitle =
        mediaLoading
            ? 'Aguarde. A prévia libera em alguns segundos.'
            : librarySyncing
            ? 'As imagens da biblioteca estão sendo publicadas.'
            : hasPersonalVideo
            ? 'Confira a prévia ou troque seu vídeo.'
            : hasLibraryDemo
            ? 'Assista à demo da biblioteca ou envie seu vídeo.'
            : 'Envie sua demonstração antes de prescrever.';

    final uploadLabel =
        hasPersonalVideo
            ? 'Trocar vídeo'
            : hasLibraryDemo
            ? 'Enviar meu vídeo'
            : 'Enviar vídeo';

    final decoration = fxListCardDecoration(
      context,
      accent: hasAnyMedia || librarySyncing ? primary : null,
    );

    if (dense) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: AppTypography.inter(
                          color: ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        statusSubtitle,
                        style: AppTypography.inter(
                          color: mute,
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _DenseActions(
              primary: primary,
              mute: mute,
              mediaLoading: mediaLoading,
              hasPersonalVideo: hasPersonalVideo,
              hasLibraryDemo: hasLibraryDemo,
              hasAnyMedia: hasAnyMedia,
              uploadLabel: uploadLabel,
              onPreview: onPreview,
              onUpload: onUpload,
              onRemove: onRemove,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: decoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: AppTypography.inter(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusSubtitle,
                  maxLines: 3,
                  style: AppTypography.inter(
                    color: mute,
                    fontSize: 11.2,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (hasAnyMedia && !mediaLoading)
            TextButton(
              onPressed: onPreview,
              style: TextButton.styleFrom(
                foregroundColor: primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
          else
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: FxLiquidPrimaryButton(
                label: uploadLabel,
                onPressed: mediaLoading ? null : onUpload,
                loading: mediaLoading,
                expand: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _DenseActions extends StatelessWidget {
  const _DenseActions({
    required this.primary,
    required this.mute,
    required this.mediaLoading,
    required this.hasPersonalVideo,
    required this.hasLibraryDemo,
    required this.hasAnyMedia,
    required this.uploadLabel,
    required this.onPreview,
    required this.onUpload,
    required this.onRemove,
  });

  final Color primary;
  final Color mute;
  final bool mediaLoading;
  final bool hasPersonalVideo;
  final bool hasLibraryDemo;
  final bool hasAnyMedia;
  final String uploadLabel;
  final VoidCallback onPreview;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (hasAnyMedia && !mediaLoading) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: onPreview,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.35)),
              ),
              child: Text(hasLibraryDemo ? 'Ver demo' : 'Prévia'),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: hasAnyMedia ? 1 : 2,
          child: FxLiquidPrimaryButton(
            label: uploadLabel,
            onPressed: mediaLoading ? null : onUpload,
            loading: mediaLoading,
            expand: true,
          ),
        ),
        if (hasPersonalVideo) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Remover vídeo',
            onPressed: mediaLoading ? null : onRemove,
            icon: Icon(Icons.delete_outline_rounded, color: mute),
          ),
        ],
      ],
    );
  }
}
