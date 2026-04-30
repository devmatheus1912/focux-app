import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../data/landing_tracking.dart';
import '../models/public_personal_data.dart';

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
    final firstName = data.nomePersonal.split(' ').first;
    final customHero = data.heroImageUrl?.trim();
    final generatedHero = data.generatedHeroImageUrl?.trim();
    final heroImage =
        customHero != null && customHero.isNotEmpty
            ? customHero
            : generatedHero != null && generatedHero.isNotEmpty
            ? generatedHero
            : data.fotos.isNotEmpty
            ? data.fotos.first
            : (data.logoUrl != null && data.logoUrl!.isNotEmpty
                ? data.logoUrl
                : null);
    final compact = MediaQuery.of(context).size.width < 640;
    final minHeight = (MediaQuery.of(context).size.height * 0.86).clamp(
      620.0,
      820.0,
    );

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      color: const Color(0xFF0A0F1E),
      child: Stack(
        children: [
          if (heroImage != null)
            Positioned.fill(
              child: Image.network(
                heroImage,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(
                      alpha: heroImage == null ? 0.20 : 0.44,
                    ),
                    primaryColor.withValues(
                      alpha: heroImage == null ? 0.58 : 0.34,
                    ),
                    const Color(0xFF050814).withValues(alpha: 0.96),
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
                        : CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 42,
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
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Text(
                      data.nomePersonal,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 42 : 64,
                        height: 0.98,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: compact ? TextAlign.center : TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Text(
                      (data.slogan != null && data.slogan!.trim().isNotEmpty)
                          ? data.slogan!
                          : (data.descricaoProfissional?.trim().isNotEmpty ==
                                  true
                              ? data.descricaoProfissional!
                              : 'Treinamento personalizado, acompanhamento proximo e plano feito para sua rotina.'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: compact ? 16 : 19,
                        height: 1.45,
                      ),
                      textAlign: compact ? TextAlign.center : TextAlign.left,
                      maxLines: compact ? 4 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment:
                        compact ? WrapAlignment.center : WrapAlignment.start,
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
                          'Quero treinar com $firstName',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment:
                        compact ? WrapAlignment.center : WrapAlignment.start,
                    children: [
                      _HeroPill(value: '${data.totalAlunos}+', label: 'alunos'),
                      _HeroPill(
                        value: 'Desde ${data.anoCriacao}',
                        label: 'experiencia',
                      ),
                      if (data.especialidades?.trim().isNotEmpty == true)
                        _HeroPill(
                          value: data.especialidades!.split(',').first.trim(),
                          label: 'foco',
                        ),
                    ],
                  ),
                  if (data.videoUrl?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 24),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.36),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: _InlinePresentationVideo(
          url: url,
          brand: primaryColor,
          slug: slug,
          trackingId: trackingId,
        ),
      ),
    );
  }
}

class _InlinePresentationVideo extends StatefulWidget {
  final String url;
  final Color brand;
  final String slug;
  final String? trackingId;

  const _InlinePresentationVideo({
    required this.url,
    required this.brand,
    required this.slug,
    required this.trackingId,
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
    if (!_ready) {
      return const SizedBox(
        height: 190,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio:
                _controller.value.aspectRatio == 0
                    ? 16 / 9
                    : _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
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
            const Expanded(
              child: Text(
                'Video de apresentacao',
                style: TextStyle(
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
