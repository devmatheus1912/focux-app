import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../data/landing_tracking.dart';
import '../models/public_personal_data.dart';
import 'landing_design_helpers.dart';

class HeroSection extends StatelessWidget {
  final PublicPersonalData data;
  final String slug;
  final Color primaryColor;
  final Color secondaryColor;

  const HeroSection({
    super.key,
    required this.data,
    required this.slug,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final heroImage = LandingDesign.firstImageUrl(data);
    assert(heroImage == null || !_isAiGeneratedHeroUrl(heroImage));
    final compact = MediaQuery.of(context).size.width < 640;
    final signature = _signatureVariant(slug, data.nomePersonal);
    final composition = _compositionVariant(slug, data.nomePersonal);
    final minHeight = (MediaQuery.of(context).size.height *
            (compact ? 0.94 : 0.88))
        .clamp(compact ? 700.0 : 620.0, compact ? 900.0 : 820.0);
    final headline = LandingDesign.heroHeadline(data);
    final support = LandingDesign.heroSupport(data);
    final ctaLabel = LandingDesign.heroCta(data);
    final heroPills = LandingDesign.heroPills(data);
    final alignRight = !compact && composition == _LandingComposition.editorial;

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      color: const Color(0xFF0A0F1E),
      child: Stack(
        children: [
          Positioned.fill(
            child: _LandingBrandCanvas(
              primary: primaryColor,
              secondary: secondaryColor,
              variant: signature,
              composition: composition,
            ),
          ),
          if (heroImage != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.78,
                child: Image.network(
                  heroImage,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: compact ? Alignment.topCenter : Alignment.centerLeft,
                  end: compact ? Alignment.bottomCenter : Alignment.centerRight,
                  colors: [
                    const Color(0xFF050814).withValues(alpha: 0.98),
                    const Color(
                      0xFF050814,
                    ).withValues(alpha: heroImage == null ? 0.74 : 0.62),
                    primaryColor.withValues(
                      alpha: heroImage == null ? 0.44 : 0.26,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 24 : 72,
                28,
                compact ? 24 : 72,
                42,
              ),
              child: Column(
                crossAxisAlignment:
                    compact
                        ? CrossAxisAlignment.center
                        : alignRight
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment:
                          compact
                              ? MainAxisAlignment.center
                              : alignRight
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          backgroundImage:
                              data.logoUrl != null && data.logoUrl!.isNotEmpty
                                  ? NetworkImage(data.logoUrl!) as ImageProvider
                                  : null,
                          child:
                              data.logoUrl != null && data.logoUrl!.isNotEmpty
                                  ? null
                                  : Text(
                                    data.nomePersonal.isNotEmpty
                                        ? data.nomePersonal[0].toUpperCase()
                                        : 'P',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: _SignatureBadge(
                            label:
                                '${data.nomePersonal} - ${signature.label} ${composition.label}',
                            primary: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Text(
                      headline,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 40 : 70,
                        height: 0.98,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign:
                          compact
                              ? TextAlign.center
                              : alignRight
                              ? TextAlign.right
                              : TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Text(
                      support,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: compact ? 16 : 19,
                        height: 1.45,
                      ),
                      textAlign:
                          compact
                              ? TextAlign.center
                              : alignRight
                              ? TextAlign.right
                              : TextAlign.left,
                      maxLines: compact ? 4 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment:
                        compact
                            ? WrapAlignment.center
                            : alignRight
                            ? WrapAlignment.end
                            : WrapAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          final path = landingRegisterPath(
                            slug,
                            data.trackingId,
                            source: 'landing',
                          );
                          trackLandingEvent(
                            slug: slug,
                            eventType: 'landing_cta_click',
                            source: 'landing',
                            trackingId: data.trackingId,
                            path: path,
                          );
                          context.go(path);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          ctaLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment:
                        compact
                            ? WrapAlignment.center
                            : alignRight
                            ? WrapAlignment.end
                            : WrapAlignment.start,
                    children:
                        heroPills
                            .map(
                              (item) => _HeroPill(
                                value: item.value,
                                label: item.label,
                              ),
                            )
                            .toList(),
                  ),
                  if (data.videoUrl?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 22),
                    _PresentationVideoCard(
                      url: data.videoUrl!.trim(),
                      slug: slug,
                      trackingId: data.trackingId,
                      primaryColor: primaryColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresentationVideoCard extends StatelessWidget {
  final String url;
  final String slug;
  final String? trackingId;
  final Color primaryColor;

  const _PresentationVideoCard({
    required this.url,
    required this.slug,
    required this.trackingId,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!_isDirectVideoUrl(url)) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: _InlinePresentationVideo(
              url: url,
              brand: primaryColor,
              slug: slug,
              trackingId: trackingId,
              compact: compact,
            ),
          ),
        );
      },
    );
  }
}

class _InlinePresentationVideo extends StatefulWidget {
  final String url;
  final Color brand;
  final String slug;
  final String? trackingId;
  final bool compact;

  const _InlinePresentationVideo({
    required this.url,
    required this.brand,
    required this.slug,
    required this.trackingId,
    required this.compact,
  });

  @override
  State<_InlinePresentationVideo> createState() =>
      _InlinePresentationVideoState();
}

class _InlinePresentationVideoState extends State<_InlinePresentationVideo> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frameHeight = widget.compact ? 245.0 : 320.0;
    if (!_ready) {
      return SizedBox(
        height: frameHeight,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    final videoSize = _controller.value.size;
    final videoWidth = videoSize.width == 0 ? 16.0 : videoSize.width;
    final videoHeight = videoSize.height == 0 ? 9.0 : videoSize.height;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: frameHeight,
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: videoWidth,
                height: videoHeight,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: widget.brand,
                foregroundColor: Colors.white,
              ),
              onPressed:
                  () => setState(() {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      trackLandingEvent(
                        slug: widget.slug,
                        eventType: 'landing_video_click',
                        source: 'landing_video',
                        trackingId: widget.trackingId,
                        path: widget.url,
                      );
                      _controller.play();
                    }
                  }),
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.compact
                    ? 'Apresentacao do personal'
                    : 'Assista antes de decidir',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

bool _isDirectVideoUrl(String url) {
  final clean = url.toLowerCase().split('?').first;
  return clean.endsWith('.mp4') ||
      clean.endsWith('.webm') ||
      clean.endsWith('.mov') ||
      clean.endsWith('.m4v');
}

bool _isAiGeneratedHeroUrl(String url) {
  return url.trim().toLowerCase().contains('image.pollinations.ai/prompt/');
}

_LandingSignature _signatureVariant(String slug, String name) {
  final source = '$slug-$name';
  var hash = 0;
  for (final code in source.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return _LandingSignature.values[hash % _LandingSignature.values.length];
}

_LandingComposition _compositionVariant(String slug, String name) {
  final source = 'composition-$slug-$name';
  var hash = 0;
  for (final code in source.codeUnits) {
    hash = (hash * 37 + code) & 0x7fffffff;
  }
  return _LandingComposition.values[hash % _LandingComposition.values.length];
}

enum _LandingSignature {
  precision('Precision'),
  studio('Studio'),
  performance('Performance');

  final String label;
  const _LandingSignature(this.label);
}

enum _LandingComposition {
  editorial('Editorial'),
  studio('Studio'),
  arena('Arena');

  final String label;
  const _LandingComposition(this.label);
}

class _LandingBrandCanvas extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final _LandingSignature variant;
  final _LandingComposition composition;

  const _LandingBrandCanvas({
    required this.primary,
    required this.secondary,
    required this.variant,
    required this.composition,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LandingBrandPainter(
        primary: primary,
        secondary: secondary,
        variant: variant,
        composition: composition,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LandingBrandPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final _LandingSignature variant;
  final _LandingComposition composition;

  const _LandingBrandPainter({
    required this.primary,
    required this.secondary,
    required this.variant,
    required this.composition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF050814),
              Color.lerp(primary, const Color(0xFF050814), 0.74)!,
              Color.lerp(secondary, const Color(0xFF050814), 0.70)!,
            ],
          ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final linePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.055)
          ..strokeWidth = 1;
    final step =
        composition == _LandingComposition.studio
            ? 38.0
            : variant == _LandingSignature.studio
            ? 42.0
            : 56.0;
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        linePaint,
      );
    }

    final bandPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = variant == _LandingSignature.performance ? 18 : 12
          ..color = primary.withValues(alpha: 0.22);
    final band = Path();
    if (composition == _LandingComposition.arena) {
      band.moveTo(size.width * 0.16, size.height + 30);
      band.lineTo(size.width * 0.72, -40);
      band.moveTo(size.width * 0.44, size.height + 40);
      band.lineTo(size.width + 40, size.height * 0.16);
    } else if (variant == _LandingSignature.precision) {
      band.moveTo(size.width * 0.58, -40);
      band.lineTo(size.width * 0.95, size.height * 0.42);
      band.lineTo(size.width * 0.70, size.height + 60);
    } else if (variant == _LandingSignature.studio) {
      band.moveTo(size.width * 0.76, -30);
      band.cubicTo(
        size.width,
        size.height * 0.22,
        size.width * 0.54,
        size.height * 0.58,
        size.width * 0.92,
        size.height + 30,
      );
    } else {
      band.moveTo(size.width * 0.40, -20);
      band.lineTo(size.width + 40, size.height * 0.24);
      band.moveTo(size.width * 0.52, size.height + 20);
      band.lineTo(size.width + 20, size.height * 0.56);
    }
    canvas.drawPath(band, bandPaint);

    final panelPaint =
        Paint()
          ..color = secondary.withValues(alpha: 0.16)
          ..style = PaintingStyle.fill;
    final panel =
        Path()
          ..moveTo(size.width * 0.70, size.height * 0.10)
          ..lineTo(size.width, size.height * 0.02)
          ..lineTo(size.width, size.height * 0.72)
          ..lineTo(size.width * 0.82, size.height * 0.92)
          ..close();
    canvas.drawPath(panel, panelPaint);
  }

  @override
  bool shouldRepaint(covariant _LandingBrandPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.variant != variant ||
        oldDelegate.composition != composition;
  }
}

class _SignatureBadge extends StatelessWidget {
  final String label;
  final Color primary;

  const _SignatureBadge({required this.label, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String value;
  final String label;

  const _HeroPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
