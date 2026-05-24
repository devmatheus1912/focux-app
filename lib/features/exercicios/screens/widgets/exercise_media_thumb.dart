import 'package:flutter/material.dart';

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
                errorBuilder: (_, __, ___) => _fallback(primary),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    width: size,
                    height: size,
                    child: Center(
                      child: SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
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
  for (final raw in [thumbnailUrl, gifUrl]) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) continue;
    if (value.contains('/video/upload/')) {
      return cloudinaryVideoPosterUrl(value) ?? value;
    }
    if (value.endsWith('.mp4') || value.endsWith('.mov')) {
      return cloudinaryVideoPosterUrl(value) ?? value;
    }
    return value;
  }
  final video = videoUrl?.trim();
  if (video != null && video.isNotEmpty) {
    return cloudinaryVideoPosterUrl(video);
  }
  return null;
}

/// Gera URL de poster JPG a partir de vídeo Cloudinary (evita usar MP4 no Image).
String? cloudinaryVideoPosterUrl(String videoUrl) {
  const marker = '/video/upload/';
  if (!videoUrl.contains(marker)) return null;
  if (videoUrl.contains('f_jpg') || videoUrl.contains('/image/upload/')) {
    return videoUrl;
  }
  final transformed = videoUrl.replaceFirst(
    marker,
    '${marker}so_0,f_jpg,w_160,h_160,c_fill,q_auto/',
  );
  return transformed.replaceAll(
    RegExp(r'\.(mp4|mov|webm|m4v)(\?.*)?$', caseSensitive: false),
    '.jpg',
  );
}
