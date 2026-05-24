import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_shell_scaffold.dart';
import '../../data/exercicio_repository.dart';
import '../../services/biblioteca_sync_status.dart';
import 'exercise_media_thumb.dart';

/// Abre prévia do vídeo próprio ou da demonstração da biblioteca (GIF).
Future<void> showExerciseMediaPreview(
  BuildContext context, {
  required Exercicio exercicio,
}) {
  final video = exercicio.videoUrl?.trim();
  if (video != null && video.isNotEmpty) {
    return showExerciseVideoPreview(context, exercicio: exercicio, url: video);
  }
  final gif = exercicio.gifUrl?.trim();
  if (gif == null || gif.isEmpty) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.52),
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
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.52),
    builder:
        (_) => ExerciseVideoPreviewSheet(exercicio: exercicio, url: resolved),
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
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final bottom = MediaQuery.of(context).padding.bottom;

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

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 10, 16, 16),
              decoration: fxListCardDecoration(context, accent: primary),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.exercicio.nomeDisplay,
                    style: AppTypography.inter(
                      color: ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    showSyncOnly
                        ? (sync.message ??
                            'Sincronizando demonstração da biblioteca...')
                        : 'Demonstração da biblioteca',
                    style: AppTypography.inter(
                      color: mute,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 1,
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
                ],
              ),
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
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 12),
            Text(
              'Carregando demonstração...',
              style: AppTypography.inter(color: mute),
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
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            pending
                ? 'Demonstração ainda sincronizando.\nTente novamente em instantes.'
                : 'Prévia indisponível agora.',
            textAlign: TextAlign.center,
            style: AppTypography.inter(color: mute, height: 1.35),
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
  });

  final Exercicio exercicio;
  final String url;

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
    if (mounted) setState(() { _ready = false; _failed = false; });

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
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 10, 16, 16),
          decoration: fxListCardDecoration(context, accent: primary),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.exercicio.nomeDisplay,
                style: AppTypography.inter(
                  color: ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: _ready && _controller != null
                      ? _controller!.value.aspectRatio
                      : 16 / 9,
                  child: ColoredBox(
                    color: Colors.black,
                    child:
                        _failed
                            ? Center(
                              child: Text(
                                'Prévia indisponível agora.',
                                style: AppTypography.inter(color: mute),
                              ),
                            )
                            : _ready && _controller != null
                            ? VideoPlayer(_controller!)
                            : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
