import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/checkin_execucao_display.dart';
import '../utils/checkin_video_badge.dart';

/// Preferred preview height for thumbnails / loading, capped by screen.
const double checkinMediaPreviewHeight = 228;

/// Alvo mínimo do play/pause sobre o vídeo.
const double checkinMediaPlayMin = 48;

double _previaAltura(BuildContext context) => checkinMediaPreviaAltura(
  preferida: checkinMediaPreviewHeight,
  alturaTela: MediaQuery.sizeOf(context).height,
);

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
          FxCachedNetworkImage(
            imageUrl: url,
            height: _previaAltura(context),
            width: double.infinity,
            fit: BoxFit.cover,
            memCacheWidth: 720,
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
          FxCachedNetworkImage(
            imageUrl: url,
            height: _previaAltura(context),
            width: double.infinity,
            fit: BoxFit.cover,
            memCacheWidth: 720,
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
            child: _CheckinMediaBadge(
              label: S.of(context).checkinMidiaTecnica,
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
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _playing = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load(widget.url);
  }

  @override
  void didUpdateWidget(CheckinExerciseVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _load(widget.url);
    }
  }

  Future<void> _release(VideoPlayerController? controller) async {
    if (controller == null) return;
    controller.removeListener(_onVideoTick);
    if (identical(_controller, controller)) {
      _controller = null;
    }
    await controller.dispose();
  }

  Future<void> _load(String url) async {
    final generation = ++_loadGeneration;
    // Drop any published controller before starting a new load.
    final previous = _controller;
    _controller = null;
    await _release(previous);
    if (!mounted || generation != _loadGeneration) return;

    setState(() {
      _ready = false;
      _failed = false;
      _playing = false;
    });

    // Keep the controller local until ready so cancel/error always owns cleanup.
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    controller.addListener(_onVideoTick);

    try {
      await controller.initialize();
      if (!mounted || generation != _loadGeneration) {
        await _release(controller);
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted || generation != _loadGeneration) {
        await _release(controller);
        return;
      }
      _controller = controller;
      setState(() {
        _ready = true;
        _playing = controller.value.isPlaying;
      });
    } catch (_) {
      await _release(controller);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _failed = true;
        _ready = false;
      });
    }
  }

  void _onVideoTick() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final playing = controller.value.isPlaying;
    if (playing == _playing) return;
    setState(() => _playing = playing);
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || !_ready) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  @override
  void dispose() {
    // Invalidate in-flight loads; their local controller is released in _load.
    _loadGeneration++;
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_onVideoTick);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return CheckinVideoFallback(brand: widget.brand, dark: widget.dark);
    }
    final controller = _controller;
    if (!_ready || controller == null) {
      return Container(
        height: _previaAltura(context),
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
    final video = controller.value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          LayoutBuilder(
            builder:
                (context, constraints) => Container(
                  color: Colors.black,
                  width: double.infinity,
                  height: checkinMediaAltura(
                    largura: constraints.maxWidth,
                    alturaTela: MediaQuery.sizeOf(context).height,
                    aspectRatio: video.aspectRatio,
                  ),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: video.size.width > 0 ? video.size.width : 16,
                      height: video.size.height > 0 ? video.size.height : 9,
                      child: VideoPlayer(controller),
                    ),
                  ),
                ),
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
            right: 6,
            bottom: 6,
            child: CheckinVideoPlayButton(playing: _playing, onTap: _togglePlay),
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

class CheckinVideoPlayButton extends StatelessWidget {
  const CheckinVideoPlayButton({
    super.key,
    required this.playing,
    required this.onTap,
  });

  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final label = playing ? s.checkinVideoPausar : s.checkinVideoReproduzir;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Material(
          color: Colors.black.withValues(alpha: 0.42),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: checkinMediaPlayMin,
              height: checkinMediaPlayMin,
              child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
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
            S.of(context).checkinMidiaVideoPersonal,
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
