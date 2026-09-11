import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import '../utils/checkin_video_badge.dart';

/// Fixed preview height for thumbnails / loading (demo sheet + inline).
const double checkinMediaPreviewHeight = 228;

class CheckinExerciseThumbnailPreview extends StatelessWidget {
  final String url;
  final String? videoSource;
  final String? licenseStatus;
  final Color brand;
  final bool dark;

  const CheckinExerciseThumbnailPreview({
    super.key,
    required this.url,
    required this.videoSource,
    required this.licenseStatus,
    required this.brand,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final badge = CheckinVideoBadge.label(
      licenseStatus: licenseStatus,
      videoSource: videoSource,
    );
    final badgeIcon = CheckinVideoBadge.icon(
      licenseStatus: licenseStatus,
      videoSource: videoSource,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Image.network(
            url,
            height: checkinMediaPreviewHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => Container(
                  height: 120,
                  color:
                      dark ? EagleTokens.darkCardHi : TokensStrip.borderDefault,
                  alignment: Alignment.center,
                  child: Icon(Icons.play_circle_outline_rounded, color: brand),
                ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.22),
                  ],
                ),
              ),
            ),
          ),
          if (badge != null && badgeIcon != null)
            Positioned(
              left: 10,
              bottom: 10,
              child: _CheckinMediaBadge(label: badge, icon: badgeIcon),
            ),
        ],
      ),
    );
  }
}

class CheckinExerciseMediaPreview extends StatelessWidget {
  final String url;
  final Color brand;
  final bool dark;

  const CheckinExerciseMediaPreview({
    super.key,
    required this.url,
    required this.brand,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Image.network(
            url,
            height: checkinMediaPreviewHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => Container(
                  height: 120,
                  color:
                      dark ? EagleTokens.darkCardHi : TokensStrip.borderDefault,
                  alignment: Alignment.center,
                  child: Icon(Icons.play_circle_outline_rounded, color: brand),
                ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.20),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: const _CheckinMediaBadge(
              label: 'Tecnica do exercicio',
              icon: Icons.play_arrow_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class CheckinExerciseVideoPreview extends StatefulWidget {
  final String url;
  final Color brand;
  final bool dark;
  final String? videoSource;
  final String? licenseStatus;

  const CheckinExerciseVideoPreview({
    super.key,
    required this.url,
    required this.brand,
    required this.dark,
    this.videoSource,
    this.licenseStatus,
  });

  @override
  State<CheckinExerciseVideoPreview> createState() =>
      _CheckinExerciseVideoPreviewState();
}

class _CheckinExerciseVideoPreviewState
    extends State<CheckinExerciseVideoPreview> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..addListener(_onVideoTick)
      ..initialize()
          .then((_) async {
            if (!mounted) return;
            await _controller.setLooping(true);
            await _controller.setVolume(0);
            await _controller.play();
            if (!mounted) return;
            setState(() {
              _ready = true;
              _playing = _controller.value.isPlaying;
            });
          })
          .catchError((_) {
            if (mounted) setState(() => _failed = true);
          });
  }

  void _onVideoTick() {
    final playing = _controller.value.isPlaying;
    if (playing == _playing || !mounted) return;
    setState(() => _playing = playing);
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return CheckinVideoFallback(brand: widget.brand, dark: widget.dark);
    }
    if (!_ready) {
      return Container(
        height: checkinMediaPreviewHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color:
              widget.dark ? EagleTokens.darkCardHi : TokensStrip.borderDefault,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.brand.withValues(alpha: 0.22)),
        ),
        alignment: Alignment.center,
        child: FxLoading(color: widget.brand, strokeWidth: 2.5),
      );
    }

    final badge = CheckinVideoBadge.label(
      licenseStatus: widget.licenseStatus,
      videoSource: widget.videoSource,
    );
    final badgeIcon = CheckinVideoBadge.icon(
      licenseStatus: widget.licenseStatus,
      videoSource: widget.videoSource,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio:
                _controller.value.aspectRatio == 0
                    ? 16 / 9
                    : _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Material(
              color: Colors.black.withValues(alpha: 0.42),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _togglePlay,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          if (badge != null && badgeIcon != null)
            Positioned(
              left: 10,
              bottom: 10,
              child: _CheckinMediaBadge(label: badge, icon: badgeIcon),
            ),
        ],
      ),
    );
  }
}

class _CheckinMediaBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CheckinMediaBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class CheckinVideoFallback extends StatelessWidget {
  final Color brand;
  final bool dark;

  const CheckinVideoFallback({
    super.key,
    required this.brand,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? EagleTokens.darkCardHi : TokensStrip.borderDefault,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brand.withValues(alpha: 0.26)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_fill_rounded, color: brand, size: 34),
          const SizedBox(height: 6),
          Text(
            'Vídeo próprio do personal disponível',
            style: TextStyle(
              color: brand,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
