import 'package:flutter/material.dart';

class ExerciseMediaThumb extends StatelessWidget {
  const ExerciseMediaThumb({
    super.key,
    this.mediaUrl,
    this.size = 44,
    this.radius = 14,
    this.iconSize = 20,
  });

  final String? mediaUrl;
  final double size;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final url = mediaUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
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
      );
    }
    return _fallback(primary);
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
  for (final raw in [thumbnailUrl, gifUrl, videoUrl]) {
    final value = raw?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}
