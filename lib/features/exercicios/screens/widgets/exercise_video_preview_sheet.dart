import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_home_sheet.dart';
import '../../../../core/widgets/fx_loading.dart';
import '../../data/exercicio_repository.dart';
import '../../services/biblioteca_media_config.dart';
import '../../services/biblioteca_sync_status.dart';
import 'exercise_media_thumb.dart';

/// Abre prévia do vídeo próprio ou da demonstração da biblioteca (GIF/MoveKit).
Future<void> showExerciseMediaPreview(
  BuildContext context, {
  required Exercicio exercicio,
}) {
  final video = exercicio.videoUrl?.trim();
  if (video != null && video.isNotEmpty) {
    return showExerciseVideoPreview(context, exercicio: exercicio, url: video);
  }
  // Sem mídia publicada: não abrir sheet "em breve" (§38 hide do stub).
  if (!exercicioHasPublishedLibraryMedia(exercicio)) {
    return Future.value();
  }
  final gif = exercicio.gifUrl?.trim();
  if (gif == null || gif.isEmpty) return Future.value();
  return showFxHomeSheet<void>(
    context,
    builder: (_) => ExerciseGifPreviewSheet(exercicio: exercicio, url: gif),
  );
}

Future<void> showExerciseVideoPreview(
  BuildContext context, {
  required Exercicio exercicio,
  String? url,
}) {
  final resolved = url?.trim() ?? exercicio.videoUrl?.trim();
  if (resolved == null || resolved.isEmpty) return Future.value();
  return showFxHomeSheet<void>(
    context,
    builder:
        (_) => ExerciseVideoPreviewSheet(
          exercicio: exercicio,
          url: resolved,
          isPersonalVideo: exercicioHasPersonalVideo(exercicio),
        ),
  );
}

class ExerciseGifPreviewSheet extends StatefulWidget {
  const ExerciseGifPreviewSheet({
    super.key,
    required this.exercicio,
    required this.url,
  });

  final Exercicio exercicio;
  final String url;

  @override
  State<ExerciseGifPreviewSheet> createState() =>
      _ExerciseGifPreviewSheetState();
}

class _ExerciseGifPreviewSheetState extends State<ExerciseGifPreviewSheet> {
  late final List<String> _candidates;
  int _candidateIndex = 0;
  bool _exhausted = false;

  @override
  void initState() {
    super.initState();
    _reloadCandidates();
  }

  void _reloadCandidates() {
    final seen = <String>{};
    _candidates = <String>[];
    for (final raw in exerciseLibraryPreviewCandidates(widget.exercicio)) {
      if (seen.add(raw)) _candidates.add(raw);
    }
    if (_candidates.isEmpty) {
      final fallback = widget.url.trim();
      if (fallback.isNotEmpty) _candidates.add(fallback);
    }
    _candidateIndex = 0;
    _exhausted = false;
  }

  void _tryNextCandidate() {
    if (_candidateIndex >= _candidates.length - 1) {
      setState(() => _exhausted = true);
      return;
    }
    setState(() {
      _candidateIndex += 1;
      _exhausted = _candidateIndex >= _candidates.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    if (kBibliotecaLibraryVideosStandby &&
        !exercicioHasPublishedLibraryMedia(widget.exercicio)) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: BibliotecaSyncStatus.instance,
      builder: (context, _) {
        final sync = BibliotecaSyncStatus.instance;
        final pending =
            !exercicioHasPublishedLibraryMedia(widget.exercicio) ||
            sync.syncing;
        final displayUrl =
            _candidates.isEmpty ? null : _candidates[_candidateIndex];
        final showSyncOnly = pending && (!_exhausted || sync.syncing);
        final subtitle =
            showSyncOnly
                ? (sync.message ??
                    'Sincronizando demonstração da biblioteca...')
                : 'Demonstração da biblioteca';

        return FxHomeSheetSurface(
          isDark: isDark,
          maxHeight:
              MediaQuery.sizeOf(context).height *
              FxHomeSheetChrome.maxHeightFactor,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FxHomeSheetHandle(isDark: isDark),
                SizedBox(height: TokensStrip.s4),
                FxHomeSheetHeader(
                  isDark: isDark,
                  title: widget.exercicio.nomeDisplay,
                  subtitle: subtitle,
                  leading: Icon(
                    Icons.gif_box_outlined,
                    color: primary,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.hardEdge,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    // Fundo da folha — preto no letterbox vira “risco” na prévia.
                    child: ColoredBox(
                      color: isDark
                          ? TokensStrip.cinematicSurface
                          : TokensStrip.cardBg,
                      child:
                          showSyncOnly
                              ? _PreviewLoading(mute: mute)
                              : displayUrl == null
                              ? _PreviewUnavailable(
                                mute: mute,
                                pending: pending,
                              )
                              : Image.network(
                                displayUrl,
                                key: ValueKey(displayUrl),
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                errorBuilder: (_, __, ___) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) _tryNextCandidate();
                                  });
                                  if (!_exhausted) {
                                    return _PreviewLoading(mute: mute);
                                  }
                                  return _PreviewUnavailable(
                                    mute: mute,
                                    pending: pending,
                                  );
                                },
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return _PreviewLoading(mute: mute);
                                },
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PreviewLoading extends StatelessWidget {
  const _PreviewLoading({required this.mute});

  final Color mute;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? TokensStrip.cinematicSurface : TokensStrip.cardBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FxLoading(
              size: 28,
              color: isDark ? Colors.white : TokensStrip.textPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              'Carregando demonstração...',
              style: FocuxHubTypography.bodyMuted(color: mute),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewUnavailable extends StatelessWidget {
  const _PreviewUnavailable({required this.mute, required this.pending});

  final Color mute;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? TokensStrip.cinematicSurface : TokensStrip.cardBg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            pending
                ? 'Demonstração ainda sincronizando.\nTente novamente em instantes.'
                : 'Prévia indisponível agora.',
            textAlign: TextAlign.center,
            style: FocuxHubTypography.bodyMuted(color: mute),
          ),
        ),
      ),
    );
  }
}

class ExerciseVideoPreviewSheet extends StatefulWidget {
  const ExerciseVideoPreviewSheet({
    super.key,
    required this.exercicio,
    required this.url,
    this.isPersonalVideo = false,
  });

  final Exercicio exercicio;
  final String url;
  final bool isPersonalVideo;

  @override
  State<ExerciseVideoPreviewSheet> createState() =>
      _ExerciseVideoPreviewSheetState();
}

class _ExerciseVideoPreviewSheetState extends State<ExerciseVideoPreviewSheet> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(_cloudinaryH264VideoUrl(widget.url)),
    );
    _controller = controller;
    if (mounted) {
      setState(() {
        _ready = false;
        _failed = false;
      });
    }

    try {
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      setState(() => _ready = true);
      await controller.play();
    } catch (_) {
      await controller.dispose();
      if (!mounted || _controller != controller) return;
      _controller = null;
      if (_attempt < 8) {
        _attempt += 1;
        await Future<void>.delayed(Duration(seconds: 2 + _attempt));
        if (mounted) await _loadPreview();
        return;
      }
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: widget.exercicio.nomeDisplay,
            subtitle:
                widget.isPersonalVideo
                    ? 'Seu vídeo'
                    : 'Demonstração da biblioteca',
            leading: Icon(
              Icons.play_circle_outline_rounded,
              color: primary,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.hardEdge,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ColoredBox(
                color: isDark
                    ? TokensStrip.cinematicSurface
                    : TokensStrip.cardBg,
                child:
                    _failed
                        ? Center(
                          child: Text(
                            'Prévia indisponível agora.',
                            style: FocuxHubTypography.bodyMuted(color: mute),
                          ),
                        )
                        : _ready && _controller != null
                        ? FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: _controller!.value.size.width,
                            height: _controller!.value.size.height,
                            child: VideoPlayer(_controller!),
                          ),
                        )
                        : Center(
                          child: FxLoading(
                            size: 28,
                            color: isDark
                                ? Colors.white
                                : TokensStrip.textPrimary,
                          ),
                        ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

String _cloudinaryH264VideoUrl(String rawUrl) {
  const marker = '/video/upload/';
  if (!rawUrl.contains(marker)) return rawUrl;
  final delivery = rawUrl.substring(rawUrl.indexOf(marker) + marker.length);
  if (delivery.startsWith('f_mp4') ||
      delivery.startsWith('vc_h264') ||
      delivery.startsWith('vc_auto')) {
    return rawUrl;
  }
  return rawUrl.replaceFirst(marker, '${marker}f_mp4,vc_h264/');
}
