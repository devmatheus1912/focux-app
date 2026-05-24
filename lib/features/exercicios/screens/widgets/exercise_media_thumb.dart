import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton_loader.dart';
import '../../data/exercicio_repository.dart';
import '../../services/biblioteca_media_config.dart';

class ExerciseMediaThumb extends StatelessWidget {
  const ExerciseMediaThumb({
    super.key,
    this.mediaUrl,
    this.exercicio,
    this.size = 44,
    this.radius = 14,
    this.iconSize = 20,
    this.showPlayBadge = false,
    this.expectMedia = false,
  });

  final String? mediaUrl;
  final Exercicio? exercicio;
  final double size;
  final double radius;
  final double iconSize;
  final bool showPlayBadge;
  /// Quando true e sem URL, mostra estado "sem demonstração" em vez de haltere genérico.
  final bool expectMedia;

  factory ExerciseMediaThumb.fromExercicio(
    Exercicio exercicio, {
    double size = 44,
    double radius = 14,
    double iconSize = 20,
    bool? showPlayBadge,
    Key? key,
  }) {
    final pendingPublish =
        !kBibliotecaLibraryVideosStandby &&
        exercicio.hasPlayableMedia &&
        !exercicioHasPublishedLibraryMedia(exercicio) &&
        !exercicioHasPersonalVideo(exercicio);
    return ExerciseMediaThumb(
      key: key,
      exercicio: exercicio,
      mediaUrl: exercisePreviewMediaUrlFor(exercicio),
      size: size,
      radius: radius,
      iconSize: iconSize,
      showPlayBadge:
          showPlayBadge ??
          (exercicioHasPersonalVideo(exercicio) || exercicio.hasPlayableMedia),
      expectMedia: pendingPublish,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final url = mediaUrl?.trim();
    final label = exercicio?.nomeDisplay ?? 'Exercício';
    final ex = exercicio;

    Widget thumb;
    if (url != null && url.isNotEmpty) {
      thumb = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          cacheWidth: (size * 2).round(),
          cacheHeight: (size * 2).round(),
          errorBuilder: (_, __, ___) => _fallback(primary, missing: expectMedia),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SkeletonLoader(
              width: size,
              height: size,
              borderRadius: radius,
            );
          },
        ),
      );
    } else {
      thumb = _fallback(
        primary,
        missing: expectMedia,
        personalPending:
            ex != null &&
            exercicioHasPersonalVideo(ex) &&
            (url == null || url.isEmpty),
      );
    }

    thumb = AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: ValueKey(url ?? 'fallback-${ex?.id}'),
        child: thumb,
      ),
    );

    thumb = Semantics(
      label:
          ex != null && exercicioHasPersonalVideo(ex)
              ? 'Seu vídeo de $label'
              : expectMedia
              ? 'Demonstração de $label'
              : label,
      image: url != null && url.isNotEmpty,
      child: thumb,
    );

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

  Widget _fallback(
    Color primary, {
    required bool missing,
    bool personalPending = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: missing ? 0.06 : 0.10),
        borderRadius: BorderRadius.circular(radius),
        border:
            missing || personalPending
                ? Border.all(color: primary.withValues(alpha: 0.2))
                : null,
      ),
      child: Icon(
        personalPending
            ? Icons.videocam_rounded
            : missing
            ? Icons.cloud_sync_outlined
            : Icons.fitness_center_rounded,
        color: primary.withValues(alpha: missing ? 0.55 : 1),
        size: iconSize,
      ),
    );
  }
}

bool isCloudinaryTemplateUrl(String? url) {
  final value = url?.trim();
  if (value == null || value.isEmpty) return false;
  return value.contains('/curated/gifs/') ||
      value.contains('/curated/thumbs/');
}

/// Cloudinary com versão publicada (evita templates 404 do seed).
bool isCloudinaryPublishedUrl(String? url) {
  final value = url?.trim();
  if (value == null || value.isEmpty) return false;
  if (!value.contains('res.cloudinary.com')) return true;
  if (isCloudinaryTemplateUrl(value)) return false;
  return RegExp(r'/v\d+/').hasMatch(value);
}

bool exercicioHasPublishedLibraryMedia(Exercicio exercicio) {
  if (exercicio.isPersonalUpload && exercicio.videoUrl?.trim().isNotEmpty == true) {
    return true;
  }
  return isCloudinaryPublishedUrl(exercicio.thumbnailUrl) ||
      isCloudinaryPublishedUrl(exercicio.gifUrl);
}

/// URLs para tentar carregar prévia da biblioteca (GIF, thumb, transform).
List<String> exerciseLibraryPreviewCandidates(Exercicio exercicio) {
  final seen = <String>{};
  final out = <String>[];

  void add(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty || !seen.add(value)) return;
    out.add(value);
  }

  add(exercicio.gifUrl);
  add(exercicio.thumbnailUrl);
  final gif = exercicio.gifUrl?.trim();
  if (gif != null && gif.isNotEmpty) {
    add(cloudinaryImageThumbUrl(gif));
  }
  final thumb = exercicio.thumbnailUrl?.trim();
  if (thumb != null && thumb.isNotEmpty) {
    add(cloudinaryImageThumbUrl(thumb));
  }
  return out;
}

/// URL estática para thumb na lista (prioriza vídeo do personal, depois biblioteca).
String? exercisePreviewMediaUrlFor(Exercicio exercicio) {
  if (exercicio.isPersonalUpload || exercicioHasPersonalVideo(exercicio)) {
    final thumb = exercicio.thumbnailUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) {
      final resolved =
          _resolveCloudinaryOrRaster(thumb) ?? cloudinaryImageThumbUrl(thumb);
      if (resolved != null) {
        return _cacheBustMediaUrl(resolved, exercicio.videoUrl);
      }
    }
    final video = exercicio.videoUrl?.trim();
    if (video != null && video.isNotEmpty) {
      final poster = cloudinaryVideoPosterUrl(video);
      if (poster != null) return _cacheBustMediaUrl(poster, video);
    }
    return null;
  }
  if (!exercicioHasPublishedLibraryMedia(exercicio)) return null;
  return exercisePreviewMediaUrl(
    thumbnailUrl: exercicio.thumbnailUrl,
    gifUrl: exercicio.gifUrl,
    videoUrl: exercicio.videoUrl,
  );
}

String _cacheBustMediaUrl(String url, String? seed) {
  final token = seed?.trim();
  if (token == null || token.isEmpty) return url;
  final version = RegExp(r'/v(\d+)/').firstMatch(token)?.group(1);
  if (version == null) return url;
  final separator = url.contains('?') ? '&' : '?';
  return '$url${separator}_v=$version';
}

String? exercisePreviewMediaUrl({
  String? thumbnailUrl,
  String? gifUrl,
  String? videoUrl,
}) {
  final thumb = thumbnailUrl?.trim();
  if (thumb != null && thumb.isNotEmpty) {
    final resolved = _resolveCloudinaryOrRaster(thumb);
    if (resolved != null) return resolved;
  }

  for (final raw in [gifUrl, videoUrl, thumbnailUrl]) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) continue;
    final resolved = _resolveCloudinaryOrRaster(value);
    if (resolved != null && !resolved.contains('.mp4')) return resolved;
  }
  return null;
}

String? _resolveCloudinaryOrRaster(String url) {
  if (url.contains('res.cloudinary.com') && !isCloudinaryPublishedUrl(url)) {
    return null;
  }
  if (url.contains('.gif') && url.contains('res.cloudinary.com')) {
    return cloudinaryImageThumbUrl(url) ?? url;
  }
  if (_isRasterImageUrl(url)) return url;
  final imageThumb = cloudinaryImageThumbUrl(url);
  if (imageThumb != null) return imageThumb;
  return cloudinaryVideoPosterUrl(url);
}

bool exercicioMissingPreviewPoster(Exercicio exercicio) {
  if (!exercicio.hasPlayableMedia) return false;
  if (!exercicioHasPublishedLibraryMedia(exercicio)) return true;
  final poster = exercisePreviewMediaUrlFor(exercicio);
  return poster == null || poster.contains('.mp4');
}

bool _isRasterImageUrl(String url) {
  if (url.contains('.mp4') || url.contains('.mov')) return false;
  return RegExp(
    r'\.(jpg|jpeg|png|webp|gif)(\?|$)',
    caseSensitive: false,
  ).hasMatch(url);
}

/// Thumb JPG a partir de imagem/GIF Cloudinary.
String? cloudinaryImageThumbUrl(String imageUrl) {
  if (!imageUrl.contains('res.cloudinary.com')) return null;
  const marker = '/image/upload/';
  final idx = imageUrl.indexOf(marker);
  if (idx < 0) return null;
  if (imageUrl.contains('w_160') && imageUrl.contains('c_fill')) {
    return imageUrl;
  }

  final prefix = imageUrl.substring(0, idx + marker.length);
  final after = imageUrl.substring(idx + marker.length);
  if (after.isEmpty) return null;

  var thumb = '${prefix}w_160,h_160,c_fill,q_auto/$after';
  if (thumb.contains('.gif')) {
    thumb = thumb.replaceAll(
      RegExp(r'\.gif(\?.*)?$', caseSensitive: false),
      '.jpg',
    );
  }
  return thumb;
}

/// Poster JPG a partir de vídeo Cloudinary.
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

  final pathFromVersion = afterMarker.substring(
    afterMarker.indexOf(versionMatch.group(1)!),
  );
  final poster =
      '${prefix}so_0,f_jpg,w_160,h_160,c_fill,q_auto/$pathFromVersion';
  return poster.replaceAll(
    RegExp(r'\.(mp4|mov|webm|m4v)(\?.*)?$', caseSensitive: false),
    '.jpg',
  );
}

bool exercicioHasPersonalVideo(Exercicio exercicio) {
  return exercicio.isPersonalUpload &&
      exercicio.videoUrl?.trim().isNotEmpty == true;
}

/// Abre prévia útil: vídeo próprio, demo publicada ou sheet standby.
bool canPreviewExerciseMedia(Exercicio exercicio) {
  if (exercicioHasPersonalVideo(exercicio)) return true;
  if (exercicioHasPublishedLibraryMedia(exercicio)) return true;
  if (kBibliotecaLibraryVideosStandby && exercicio.curado) return true;
  return exercicio.hasPlayableMedia;
}
