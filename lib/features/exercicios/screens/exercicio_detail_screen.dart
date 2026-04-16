import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../providers/exercicios_provider.dart';

class ExercicioDetailScreen extends ConsumerWidget {
  final int exercicioId;
  const ExercicioDetailScreen({super.key, required this.exercicioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercicioAsync = ref.watch(exercicioProvider(exercicioId));

    return Scaffold(
      appBar: AppBar(title: const Text('Exercício')),
      body: exercicioAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (ex) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ex.gifUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(ex.gifUrl!, height: 200, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                ),
              const SizedBox(height: 16),
              Text(ex.nome, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              if (ex.musculoAlvo != null)
                Chip(label: Text(ex.musculoAlvo!)),
              if (ex.categoria != null)
                Chip(label: Text(ex.categoria!)),
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
