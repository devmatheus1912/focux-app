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

  Future<void> _updateEditorialReview(
    BuildContext context,
    String status,
    String? currentNotes,
  ) async {
    final notesCtrl = TextEditingController(text: currentNotes ?? '');
    final notes = await showDialog<String?>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(_editorialActionTitle(status)),
            content: TextField(
              controller: notesCtrl,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Notas tecnicas, fonte do video ou motivo da decisao',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, notesCtrl.text.trim()),
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
    notesCtrl.dispose();
    if (notes == null) return;

    try {
      await ref.read(exercicioRepositoryProvider).atualizarCuradoriaEditorial(
            id: widget.exercicioId,
            status: status,
            notes: notes.isEmpty ? null : notes,
          );
      ref.invalidate(exercicioProvider(widget.exercicioId));
      ref.invalidate(exerciciosFilteredProvider);
      ref.invalidate(exerciciosCuradoriaProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Curadoria marcada como ${_formatEditorialStatus(status)}.')),
      );
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar curadoria: $e')),
        );
      }
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
                      if (ex.gifUrl != null || ex.thumbnailUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            ex.gifUrl ?? ex.thumbnailUrl!,
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
                          if (ex.equipamento != null && ex.equipamento!.isNotEmpty)
                            Chip(
                              avatar: const Icon(Icons.construction_rounded, size: 16),
                              label: Text(ex.equipamento!),
                            ),
                          if (ex.nivel != null && ex.nivel!.isNotEmpty)
                            Chip(
                              avatar: const Icon(Icons.trending_up_rounded, size: 16),
                              label: Text(ex.nivel!),
                            ),
                          if (ex.mecanica != null && ex.mecanica!.isNotEmpty)
                            Chip(
                              avatar: const Icon(Icons.account_tree_rounded, size: 16),
                              label: Text(ex.mecanica!),
                            ),
                          if (ex.objetivo != null && ex.objetivo!.isNotEmpty)
                            Chip(
                              avatar: const Icon(Icons.flag_rounded, size: 16),
                              label: Text(ex.objetivo!),
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
                      if (ex.videoSource?.isNotEmpty == true || ex.licenseStatus?.isNotEmpty == true) ...[
                        _EditorialReviewPanel(
                          status: ex.editorialStatus,
                          notes: ex.editorialNotes,
                          reviewedAt: ex.editorialReviewedAt,
                          onChange: (status) => _updateEditorialReview(
                            context,
                            status,
                            ex.editorialNotes,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _MediaMetadataPanel(
                          source: ex.videoSource,
                          licenseStatus: ex.licenseStatus,
                        ),
                        const SizedBox(height: 12),
                      ],
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
                      if (ex.errosComuns?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        _GuidanceCard(
                          icon: Icons.report_problem_outlined,
                          title: 'Erros comuns',
                          text: ex.errosComuns!.trim(),
                          color: EagleTokens.warn,
                        ),
                      ],
                      if (ex.contraindicacoes?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        _GuidanceCard(
                          icon: Icons.health_and_safety_outlined,
                          title: 'Contraindicacoes',
                          text: ex.contraindicacoes!.trim(),
                          color: EagleTokens.bad,
                        ),
                      ],
                      if (ex.substitutos?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        _GuidanceCard(
                          icon: Icons.swap_horiz_rounded,
                          title: 'Substitutos',
                          text: ex.substitutos!.trim(),
                          color: Theme.of(context).colorScheme.primary,
                        ),
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

String _formatEditorialStatus(String value) {
  return switch (value) {
    'APPROVED' => 'Aprovado',
    'REJECTED' => 'Reprovado',
    _ => 'Pendente',
  };
}

String _editorialActionTitle(String value) {
  return switch (value) {
    'APPROVED' => 'Aprovar midia',
    'REJECTED' => 'Reprovar midia',
    _ => 'Voltar para revisao',
  };
}

class _EditorialReviewPanel extends StatelessWidget {
  final String status;
  final String? notes;
  final DateTime? reviewedAt;
  final ValueChanged<String> onChange;

  const _EditorialReviewPanel({
    required this.status,
    required this.notes,
    required this.reviewedAt,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final color = switch (status) {
      'APPROVED' => EagleTokens.good,
      'REJECTED' => EagleTokens.bad,
      _ => EagleTokens.warn,
    };
    final reviewed =
        reviewedAt == null
            ? null
            : '${reviewedAt!.day.toString().padLeft(2, '0')}/'
                '${reviewedAt!.month.toString().padLeft(2, '0')}/'
                '${reviewedAt!.year}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_rounded, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Curadoria editorial',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        _formatEditorialStatus(status),
                        if (reviewed != null) 'revisado em $reviewed',
                      ].join(' · '),
                      style: TextStyle(
                        color: mute,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (notes?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              notes!.trim(),
              style: TextStyle(
                color: ink.withValues(alpha: 0.84),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _EditorialActionButton(
                label: 'Aprovar',
                icon: Icons.verified_rounded,
                selected: status == 'APPROVED',
                onTap: () => onChange('APPROVED'),
              ),
              _EditorialActionButton(
                label: 'Reprovar',
                icon: Icons.block_rounded,
                selected: status == 'REJECTED',
                onTap: () => onChange('REJECTED'),
              ),
              _EditorialActionButton(
                label: 'Revisar',
                icon: Icons.rate_review_rounded,
                selected: status == 'PENDING_REVIEW',
                onTap: () => onChange('PENDING_REVIEW'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorialActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _EditorialActionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor:
            selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                : null,
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _GuidanceCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: ink, fontSize: 13.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(color: ink.withValues(alpha: 0.82), fontSize: 12.8, height: 1.36)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaMetadataPanel extends StatelessWidget {
  final String? source;
  final String? licenseStatus;

  const _MediaMetadataPanel({
    required this.source,
    required this.licenseStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final licensed = licenseStatus == 'LICENSED';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Icon(
            licensed ? Icons.verified_rounded : Icons.video_library_rounded,
            color: licensed ? EagleTokens.good : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  licensed ? 'Video licenciado' : 'Origem do video',
                  style: TextStyle(color: ink, fontSize: 13.5, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (source?.isNotEmpty == true) _formatSource(source!),
                    if (licenseStatus?.isNotEmpty == true) _formatLicense(licenseStatus!),
                  ].join(' | '),
                  style: TextStyle(color: mute, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSource(String value) {
    return switch (value) {
      'FOCUX_LIBRARY' => 'Biblioteca Focux',
      'PERSONAL_UPLOAD' => 'Video do personal',
      _ => value.replaceAll('_', ' '),
    };
  }

  String _formatLicense(String value) {
    return switch (value) {
      'LICENSED' => 'Licenciado',
      'PERSONAL_OWNED' => 'Proprio',
      'PENDING_REVIEW' => 'Pendente',
      _ => value.replaceAll('_', ' '),
    };
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
