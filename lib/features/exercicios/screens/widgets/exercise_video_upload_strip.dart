import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_motion.dart';
import '../../../../core/widgets/fx_shell_scaffold.dart';
import '../../data/exercicio_repository.dart';
import '../../services/biblioteca_media_config.dart';
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
    this.quietCta = false,
    this.emptySubtitle,
    this.footer,
  });

  final Exercicio exercicio;
  final bool isDark;
  final Color primary;
  final bool mediaLoading;
  final VoidCallback onPreview;
  final VoidCallback onUpload;
  final VoidCallback onRemove;
  final bool dense;
  final bool quietCta;

  /// Copy do estado vazio. Se nulo, usa o teaser da biblioteca.
  final String? emptySubtitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    if (kBibliotecaLibraryVideosStandby) {
      return _buildContent(context, librarySyncing: false);
    }
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
        !kBibliotecaLibraryVideosStandby &&
        exercicio.hasPlayableMedia &&
        !hasPersonalVideo &&
        exercicioHasPublishedLibraryMedia(exercicio);
    final hasAnyMedia = hasPersonalVideo || hasLibraryDemo;
    final canPreview = hasPersonalVideo || hasLibraryDemo;
    final statusColor =
        hasAnyMedia || mediaLoading
            ? primary
            : isDark
            ? Colors.white.withValues(alpha: 0.68)
            : TokensStrip.textSecondary;
    final statusIcon =
        mediaLoading
            ? Icons.hourglass_top_rounded
            : hasPersonalVideo
            ? Icons.play_circle_fill_rounded
            : hasLibraryDemo
            ? Icons.video_library_rounded
            : Icons.video_call_outlined;
    final statusTitle =
        mediaLoading
            ? 'Enviando vídeo...'
            : hasPersonalVideo
            ? 'Seu vídeo está pronto'
            : hasLibraryDemo
            ? 'Demonstração da biblioteca'
            : 'Vídeo do exercício (opcional)';
    final statusSubtitle =
        mediaLoading
            ? 'Não feche o app. A miniatura atualiza em instantes.'
            : hasPersonalVideo
            ? 'Prévia, troca ou remoção a qualquer momento.'
            : hasLibraryDemo
            ? 'Assista à demo ou envie sua gravação.'
            : (emptySubtitle ??
                (kBibliotecaLibraryVideosStandby
                    ? 'Envie sua demonstração. A demo oficial Focux chega em breve.'
                    : 'Envie sua demonstração antes de prescrever.'));

    final uploadLabel = hasPersonalVideo ? 'Trocar vídeo' : 'Enviar vídeo';

    final decoration = fxListCardDecoration(
      context,
      accent: hasAnyMedia || mediaLoading ? primary : null,
    );

    if (dense) {
      return Semantics(
        liveRegion: mediaLoading,
        label:
            mediaLoading
                ? 'Enviando vídeo, aguarde. Não feche o app.'
                : '$statusTitle. $statusSubtitle',
        child: Container(
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
                canPreview: canPreview,
                uploadLabel: uploadLabel,
                quietCta: quietCta,
                onPreview: onPreview,
                onUpload: onUpload,
                onRemove: onRemove,
              ),
              if (footer != null) ...[const SizedBox(height: 8), footer!],
            ],
          ),
        ),
      );
    }

    return Semantics(
      liveRegion: mediaLoading,
      label:
          mediaLoading
              ? 'Enviando vídeo, aguarde. Não feche o app.'
              : '$statusTitle. $statusSubtitle',
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
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
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusSubtitle,
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
              ],
            ),
            if (hasPersonalVideo && !mediaLoading) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: _SourceBadge(
                  label: 'Seu vídeo',
                  color: primary,
                  isDark: isDark,
                ),
              ),
            ],
            const SizedBox(height: 10),
            _DenseActions(
              primary: primary,
              mute: mute,
              mediaLoading: mediaLoading,
              hasPersonalVideo: hasPersonalVideo,
              canPreview: canPreview,
              uploadLabel: uploadLabel,
              onPreview: onPreview,
              onUpload: onUpload,
              onRemove: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({
    required this.label,
    required this.color,
    required this.isDark,
  });

  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTypography.inter(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
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
    required this.canPreview,
    required this.uploadLabel,
    required this.onPreview,
    required this.onUpload,
    required this.onRemove,
    this.quietCta = false,
  });

  final Color primary;
  final Color mute;
  final bool mediaLoading;
  final bool hasPersonalVideo;
  final bool canPreview;
  final String uploadLabel;
  final bool quietCta;
  final VoidCallback onPreview;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (mediaLoading) {
      return Semantics(
        liveRegion: true,
        label: 'Enviando vídeo para a nuvem, aguarde.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 6,
                backgroundColor: primary.withValues(alpha: 0.12),
                color: primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Enviando para a nuvem...',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: mute,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canPreview && !mediaLoading)
          OutlinedButton(
            onPressed: onPreview,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: primary,
              side: BorderSide(color: primary.withValues(alpha: 0.35)),
            ),
            child: Text(hasPersonalVideo ? 'Ver seu vídeo' : 'Ver demo'),
          ),
        if (canPreview && !mediaLoading) const SizedBox(height: 8),
        if (!mediaLoading)
          quietCta
              ? OutlinedButton(
                onPressed: onUpload,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.45)),
                ),
                child: Text(uploadLabel),
              )
              : FxLiquidPrimaryButton(
                label: uploadLabel,
                onPressed: onUpload,
                expand: true,
              ),
        if (hasPersonalVideo) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: mediaLoading ? null : onRemove,
              icon: Icon(Icons.delete_outline_rounded, color: mute, size: 18),
              label: Text(
                'Remover vídeo',
                style: AppTypography.inter(
                  color: mute,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
