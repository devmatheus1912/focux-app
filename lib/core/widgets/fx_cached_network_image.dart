import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// URL assinada (CloudFront) muda a assinatura periodicamente; o cache usa a
/// URL sem query para não baixar a mesma imagem de novo.
String mediaCacheKey(String url) {
  final q = url.indexOf('?');
  if (q < 0) return url;
  final params = Uri.tryParse(url)?.queryParameters ?? const {};
  final assinada =
      params.containsKey('Signature') && params.containsKey('Key-Pair-Id');
  return assinada ? url.substring(0, q) : url;
}

/// ImageProvider com cache em disco — para [CircleAvatar.backgroundImage].
ImageProvider fxCachedNetworkImageProvider(String url, {int? maxWidth}) {
  return CachedNetworkImageProvider(
    url,
    maxWidth: maxWidth,
    cacheKey: mediaCacheKey(url),
  );
}

/// Image.network com cache em disco (avatares / thumbs).
class FxCachedNetworkImage extends StatelessWidget {
  const FxCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.medium,
    this.errorBuilder,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final ImageErrorWidgetBuilder? errorBuilder;
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW =
        memCacheWidth ??
        (width != null && width!.isFinite ? (width! * dpr).round() : null);
    // Never pass both axes — that forces a distorting decode size.
    final cacheH =
        cacheW != null
            ? null
            : (memCacheHeight ??
                (height != null && height!.isFinite
                    ? (height! * dpr).round()
                    : null));

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: mediaCacheKey(imageUrl),
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      memCacheWidth: cacheW,
      memCacheHeight: cacheH,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: const Duration(milliseconds: 80),
      errorWidget: (context, url, error) {
        if (errorBuilder != null) {
          return errorBuilder!(context, error, StackTrace.current);
        }
        return SizedBox(width: width, height: height);
      },
      placeholder: (context, url) => SizedBox(width: width, height: height),
    );
  }
}
