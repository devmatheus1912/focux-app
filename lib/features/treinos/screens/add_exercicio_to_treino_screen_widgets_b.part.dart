part of 'add_exercicio_to_treino_screen.dart';

class _ExercisePickerCard extends StatelessWidget {
  final Exercicio? exercicio;
  final bool isDark;
  final Color primary;
  final ExercisePickerLibraryLines libraryLines;
  final bool showPrescriptionHint;
  final bool showBrowseHint;
  final bool compactMode;
  final VoidCallback onTap;
  final bool mediaLoading;
  final bool videoExpanded;
  final VoidCallback onToggleVideo;
  final VoidCallback onPreviewVideo;
  final VoidCallback onUploadVideo;
  final VoidCallback onRemoveVideo;
  final VoidCallback onCreate;

  const _ExercisePickerCard({
    required this.exercicio,
    required this.isDark,
    required this.primary,
    required this.libraryLines,
    this.showPrescriptionHint = true,
    this.showBrowseHint = true,
    this.compactMode = false,
    required this.onTap,
    required this.mediaLoading,
    required this.videoExpanded,
    required this.onToggleVideo,
    required this.onPreviewVideo,
    required this.onUploadVideo,
    required this.onRemoveVideo,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final selected = exercicio != null;
    final hasMediaIssue = selected && exercicio!.showMediaBadgeInWorkoutList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: fxListCardDecoration(
                    context,
                    accent: selected ? primary : null,
                    selected: selected,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? primary
                                  : primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          selected ? Icons.check_rounded : Icons.search_rounded,
                          color: selected ? Colors.white : primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selected
                                        ? exercicio!.nomeDisplay
                                        : 'Escolher exercício',
                                    maxLines: selected ? 2 : 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.inter(
                                      color: ink,
                                      fontSize: 15,
                                      height: 1.12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (selected)
                              Text(
                                _exerciseMeta(exercicio!),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  color: _metaTextColor(isDark),
                                  fontSize: 12,
                                  height: 1.18,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    libraryLines.primary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.inter(
                                      color: _metaTextColor(isDark),
                                      fontSize: 12,
                                      height: 1.18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (libraryLines.secondary != null)
                                    Text(
                                      libraryLines.secondary!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.inter(
                                        color: _metaTextColor(isDark),
                                        fontSize: 11.5,
                                        height: 1.15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.expand_more_rounded, color: mute, size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _CreateExerciseButton(
              primary: primary,
              compact: true,
              onPressed: onCreate,
            ),
          ],
        ),
        if (!compactMode &&
            showBrowseHint &&
            (!selected || (showPrescriptionHint && !hasMediaIssue))) ...[
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: fxListCardDecoration(context, accent: primary),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.edit_note_rounded
                        : Icons.auto_awesome_motion_rounded,
                    color: primary,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selected
                          ? 'Revise a prescrição abaixo antes de adicionar.'
                          : 'Busque acima ou explore por movimento/grupo.',
                      style: AppTypography.inter(
                        color: mute,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (selected && !compactMode) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: onToggleVideo,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    videoExpanded ? Icons.expand_less : Icons.videocam_outlined,
                    color: mute,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vídeo do exercício (opcional)',
                      style: AppTypography.inter(
                        color: mute,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (videoExpanded) ...[
            const SizedBox(height: 6),
            ExerciseVideoUploadStrip(
              exercicio: exercicio!,
              isDark: isDark,
              primary: primary,
              mediaLoading: mediaLoading,
              onPreview: onPreviewVideo,
              onUpload: onUploadVideo,
              onRemove: onRemoveVideo,
            ),
          ],
        ],
      ],
    );
  }
}

class _RemoveExerciseVideoSheet extends StatelessWidget {
  final Exercicio exercicio;

  const _RemoveExerciseVideoSheet({required this.exercicio});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, bottom + 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: fxListCardDecoration(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.16)
                          : TokensStrip.borderDefault,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: EagleTokens.bad.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.videocam_off_outlined,
                      color: EagleTokens.bad,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remover vídeo?',
                          style: AppTypography.inter(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '"${exercicio.nomeDisplay}" continua na biblioteca. Só a mídia de demonstração será removida.',
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor: EagleTokens.bad,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text('Remover'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseVideoPreviewSheet extends StatefulWidget {
  final Exercicio exercicio;
  final String url;

  const _ExerciseVideoPreviewSheet({
    required this.exercicio,
    required this.url,
  });

  @override
  State<_ExerciseVideoPreviewSheet> createState() =>
      _ExerciseVideoPreviewSheetState();
}

class _ExerciseVideoPreviewSheetState
    extends State<_ExerciseVideoPreviewSheet> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  int _attempt = 0;
  static const int _maxProcessingAttempts = 10;

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
      if (_attempt < _maxProcessingAttempts) {
        _attempt += 1;
        final delaySeconds = (2 + _attempt).clamp(3, 12);
        await Future<void>.delayed(Duration(seconds: delaySeconds));
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.16)
                            : TokensStrip.borderDefault,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: EagleTokens.brandSofter,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.play_circle_outline_rounded,
                      color: primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercicio.nomeDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Confira se a demonstração está correta.',
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: mute),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: Colors.black,
                  child:
                      _failed
                          ? const _VideoPreviewFallback()
                          : !_ready
                          ? const SizedBox(
                            height: 210,
                            child: Center(child: _VideoPreparingPreview()),
                          )
                          : AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: VideoPlayer(_controller!),
                          ),
                ),
              ),
              if (_ready && !_failed && _controller != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            () => setState(() {
                              _controller!.value.isPlaying
                                  ? _controller!.pause()
                                  : _controller!.play();
                            }),
                        icon: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          _controller!.value.isPlaying
                              ? 'Pausar'
                              : 'Reproduzir',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Está certo'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPreparingPreview extends StatelessWidget {
  const _VideoPreparingPreview();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: FxLoading(color: Colors.white, strokeWidth: 2.8),
          ),
          const SizedBox(height: 12),
          Text(
            'Preparando prévia do vídeo...',
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Na primeira abertura, o Cloudinary pode levar até um minuto.',
            textAlign: TextAlign.center,
            style: AppTypography.inter(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _VideoPreviewFallback extends StatelessWidget {
  const _VideoPreviewFallback();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_file_rounded, color: Colors.white, size: 34),
            const SizedBox(height: 10),
            Text(
              'Vídeo enviado, mas a prévia ainda não ficou disponível.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Tente abrir novamente em instantes. Se persistir, envie um MP4 H.264.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(color: Colors.white70, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

String _cloudinaryH264VideoUrl(String rawUrl) {
  final url = rawUrl.trim();
  const marker = '/video/upload/';
  if (!url.contains(marker)) return url;

  final delivery = url.substring(url.indexOf(marker) + marker.length);
  if (delivery.startsWith('f_mp4') ||
      delivery.startsWith('vc_h264') ||
      delivery.startsWith('vc_auto')) {
    return url;
  }

  return url.replaceFirst(marker, '${marker}f_mp4,vc_h264/');
}
