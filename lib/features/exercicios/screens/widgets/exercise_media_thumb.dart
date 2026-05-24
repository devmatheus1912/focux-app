import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton_loader.dart';
import '../../data/exercicio_repository.dart';

class ExerciseMediaThumb extends StatelessWidget {
  const ExerciseMediaThumb({
    super.key,
    this.mediaUrl,
    this.size = 44,
    this.radius = 14,
    this.iconSize = 20,
    this.showPlayBadge = false,
  });

  final String? mediaUrl;
  final double size;
  final double radius;
  final double iconSize;
  final bool showPlayBadge;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final url = mediaUrl?.trim();
    final thumb =
        url != null && url.isNotEmpty
            ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: (size * 2).round(),
                cacheHeight: (size * 2).round(),
                errorBuilder: (_, __, ___) => _fallback(primary),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SkeletonLoader(
                    width: size,
                    height: size,
                    borderRadius: radius,
                  );
                },
              ),
            )
            : _fallback(primary);

    if (!showPlayBadge) return thumb;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        thumb,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: size * 0.42,
            height: size * 0.42,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: size * 0.26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback(Color primary) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(Icons.fitness_center_rounded, color: primary, size: iconSize),
    );
  }
}

String? exercisePreviewMediaUrl({
  String? thumbnailUrl,
  String? gifUrl,
  String? videoUrl,
}) {
  final thumb = thumbnailUrl?.trim();
  if (thumb != null && thumb.isNotEmpty && _isRasterImageUrl(thumb)) {
    return thumb;
  }

  for (final raw in [gifUrl, videoUrl, thumbnailUrl]) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) continue;
    if (_isRasterImageUrl(value)) return value;
    final poster = cloudinaryVideoPosterUrl(value);
    if (poster != null && !poster.contains('.mp4')) return poster;
  }
  return null;
}

bool exercicioMissingPreviewPoster(Exercicio exercicio) {
  if (!exercicio.hasPlayableMedia) return false;
  final poster = exercisePreviewMediaUrl(
    thumbnailUrl: exercicio.thumbnailUrl,
    gifUrl: exercicio.gifUrl,
    videoUrl: exercicio.videoUrl,
  );
  return poster == null || poster.contains('.mp4');
}

bool _isRasterImageUrl(String url) {
  if (url.contains('.mp4') || url.contains('.mov')) return false;
  return RegExp(
    r'\.(jpg|jpeg|png|webp)(\?|$)',
    caseSensitive: false,
  ).hasMatch(url);
}

/// Gera URL de poster JPG a partir de vídeo Cloudinary (evita usar MP4 no Image).
String? cloudinaryVideoPosterUrl(String videoUrl) {
  const marker = '/video/upload/';
  final idx = videoUrl.indexOf(marker);
  if (idx < 0) return null;

  if (videoUrl.contains('/image/upload/') || videoUrl.contains('f_jpg')) {
    return videoUrl;
  }

  final prefix = videoUrl.substring(0, idx + marker.length);
  final afterMarker = videoUrl.substring(idx + marker.length);
  final versionMatch = RegExp(r'(v\d+/).+').firstMatch(afterMarker);
  if (versionMatch == null) return null;

  final pathFromVersion = afterMarker.substring(afterMarker.indexOf(versionMatch.group(1)!));
  final poster =
      '${prefix}so_0,f_jpg,w_160,h_160,c_fill,q_auto/$pathFromVersion';
  return poster.replaceAll(
    RegExp(r'\.(mp4|mov|webm|m4v)(\?.*)?$', caseSensitive: false),
    '.jpg',
  );
}
