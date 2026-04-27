import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/exercicios_provider.dart';

class ExercicioDetailScreen extends ConsumerStatefulWidget {
  final int exercicioId;
  const ExercicioDetailScreen({super.key, required this.exercicioId});

  @override
  ConsumerState<ExercicioDetailScreen> createState() => _ExercicioDetailScreenState();
}

class _ExercicioDetailScreenState extends ConsumerState<ExercicioDetailScreen> {
  final _picker = ImagePicker();
  bool _uploadingVideo = false;

  Future<void> _toggleFavorito(BuildContext context, bool favoritado) async {
    final repo = ref.read(exercicioRepositoryProvider);
    try {
      if (favoritado) {
        await repo.desfavoritarExercicio(widget.exercicioId);
      } else {
        await repo.favoritarExercicio(widget.exercicioId);
      }
      ref.invalidate(exercicioProvider(widget.exercicioId));
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar favorito.')),
        );
      }
    }
  }

  Future<void> _pickAndUploadVideo(BuildContext context) async {
    XFile? file;
    try {
      file = await _picker.pickVideo(source: ImageSource.gallery);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nao foi possivel selecionar o video: $e')),
        );
      }
      return;
    }
    if (file == null) return;

    setState(() => _uploadingVideo = true);
    try {
      await ref.read(exercicioRepositoryProvider).uploadVideo(
            id: widget.exercicioId,
            bytes: await file.readAsBytes(),
            filename: file.name,
          );
      ref.invalidate(exercicioProvider(widget.exercicioId));
      ref.invalidate(exerciciosFilteredProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video proprio adicionado ao exercicio.')),
      );
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar video: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingVideo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercicioAsync = ref.watch(exercicioProvider(widget.exercicioId));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DETALHES',
                        style: TextStyle(
                          fontSize: 12,
                          color: mute,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Exercício',
                        style: TextStyle(
                          fontSize: 32,
                          color: ink,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      exercicioAsync.when(
                        data: (ex) => IconButton(
                          icon: Icon(
                            ex.favoritado ? Icons.star : Icons.star_border,
                            color: ex.favoritado ? EagleTokens.warn : mute,
                          ),
                          tooltip: ex.favoritado ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                          onPressed: () => _toggleFavorito(context, ex.favoritado),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      if (context.canPop())
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: mute),
                          onPressed: () => context.pop(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: exercicioAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: EagleTokens.brand)),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data: (ex) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (ex.gifUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            ex.gifUrl!,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(ex.nome, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      // Chips de músculo alvo e categoria
                      Wrap(
                        spacing: 8,
                        children: [
                          if (ex.musculoAlvo != null && ex.musculoAlvo!.isNotEmpty)
                            Chip(
                              avatar: const Icon(Icons.fitness_center, size: 16),
                              label: Text(ex.musculoAlvo!),
                            ),
                          if (ex.categoria != null && ex.categoria!.isNotEmpty)
                            Chip(
                              avatar: const Icon(Icons.category, size: 16),
                              label: Text(ex.categoria!),
                            ),
                        ],
                      ),
                      // Tags
                      if (ex.tags != null && ex.tags!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: ex.tags!
                              .split(',')
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .map((t) => Chip(
                                    label: Text(t, style: const TextStyle(fontSize: 12)),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.secondaryContainer,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _OwnVideoPanel(
                        hasVideo: ex.videoUrl != null && ex.videoUrl!.isNotEmpty,
                        uploading: _uploadingVideo,
                        onUpload: () => _pickAndUploadVideo(context),
                      ),
                      if (ex.videoUrl != null) ...[
                        const SizedBox(height: 12),
                        _VideoPlayer(url: ex.videoUrl!),
                      ],
                      if (ex.descricao != null && ex.descricao!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Descrição', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(ex.descricao!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayer extends StatefulWidget {
  final String url;
  const _VideoPlayer({required this.url});

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late VideoPlayerController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: _ctrl.value.aspectRatio,
            child: VideoPlayer(_ctrl),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _ctrl.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              onPressed: () => setState(() {
                _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play();
              }),
            ),
          ],
        ),
      ],
    );
  }
}

class _OwnVideoPanel extends StatelessWidget {
  final bool hasVideo;
  final bool uploading;
  final VoidCallback onUpload;

  const _OwnVideoPanel({
    required this.hasVideo,
    required this.uploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasVideo ? Icons.verified_rounded : Icons.video_call_rounded,
              color: primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasVideo ? 'Video proprio ativo' : 'Adicionar video proprio',
                  style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  hasVideo
                      ? 'Use sua demonstracao para gerar mais confianca no aluno.'
                      : 'Suba uma demonstracao sua para diferenciar este exercicio.',
                  style: TextStyle(color: mute, fontSize: 12.2, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: uploading ? null : onUpload,
            icon: uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(hasVideo ? Icons.sync_rounded : Icons.upload_rounded, size: 17),
            label: Text(hasVideo ? 'Trocar' : 'Enviar'),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(92, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
