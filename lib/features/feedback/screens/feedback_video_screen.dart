import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/feedback_video_repository.dart';

class FeedbackVideoScreen extends ConsumerStatefulWidget {
  final int? alunoId;
  final String? alunoNome;

  const FeedbackVideoScreen({super.key, this.alunoId, this.alunoNome});

  @override
  ConsumerState<FeedbackVideoScreen> createState() => _FeedbackVideoScreenState();
}

class _FeedbackVideoScreenState extends ConsumerState<FeedbackVideoScreen> {
  List<FeedbackVideo> _feedbacks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = FeedbackVideoRepository(ref.read(apiClientProvider));
      final r = widget.alunoId != null
          ? await repo.listarPorAluno(widget.alunoId!)
          : await repo.listar();
      if (mounted) setState(() { _feedbacks = r; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir a URL')));
      }
    }
  }

  Future<void> _deletar(int id) async {
    try {
      await FeedbackVideoRepository(ref.read(apiClientProvider)).deletar(id);
      _feedbacks.removeWhere((f) => f.id == id);
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao deletar: $e')));
    }
  }

  Future<void> _novoFeedback() async {
    await showDialog(
      context: context,
      builder: (ctx) => _NovoFeedbackDialog(
        alunoIdPreenchido: widget.alunoId,
        onSalvo: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? EagleTokens.darkInk : EagleTokens.ink),
        title: Text(widget.alunoNome != null ? 'Feedbacks — ${widget.alunoNome}' : 'Todos os Feedbacks de Vídeo'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
            onPressed: _load,
          )
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [EagleTokens.brand, EagleTokens.brandInk]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: EagleTokens.brand.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: FloatingActionButton(
          onPressed: _novoFeedback,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: EagleTokens.brand))
          : _feedbacks.isEmpty
              ? const Center(child: Text('Nenhum feedback encontrado.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _feedbacks.length,
                  itemBuilder: (_, i) {
                    final f = _feedbacks[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.video_library, size: 36, color: EagleTokens.brand),
                        title: Text('Exercício ID: ${f.exercicioId}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Comentário: ${f.comentario}'),
                            const SizedBox(height: 4),
                            Text('Data: ${f.criadoEm.day}/${f.criadoEm.month}/${f.criadoEm.year}', style: const TextStyle(fontSize: 12, color: EagleTokens.inkMute)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.open_in_new),
                              tooltip: 'Assistir Vídeo',
                              onPressed: () => _abrirVideo(f.videoUrl),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: EagleTokens.bad),
                              onPressed: () => _deletar(f.id),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}

class _NovoFeedbackDialog extends ConsumerStatefulWidget {
  final int? alunoIdPreenchido;
  final VoidCallback onSalvo;

  const _NovoFeedbackDialog({this.alunoIdPreenchido, required this.onSalvo});

  @override
  ConsumerState<_NovoFeedbackDialog> createState() => _NovoFeedbackDialogState();
}

class _NovoFeedbackDialogState extends ConsumerState<_NovoFeedbackDialog> {
  late TextEditingController _alunoIdCtrl;
  final _exercicioIdCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
  final _comentarioCtrl = TextEditingController();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _alunoIdCtrl = TextEditingController(text: widget.alunoIdPreenchido?.toString() ?? '');
  }

  Future<void> _salvar() async {
    final alunoId = int.tryParse(_alunoIdCtrl.text);
    final exercicioId = int.tryParse(_exercicioIdCtrl.text);
    final video = _videoUrlCtrl.text.trim();
    final com = _comentarioCtrl.text.trim();

    if (alunoId == null || exercicioId == null || video.isEmpty || com.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }

    setState(() => _salvando = true);
    try {
      await FeedbackVideoRepository(ref.read(apiClientProvider)).registrar(
        alunoId: alunoId,
        exercicioId: exercicioId,
        videoUrl: video,
        comentario: com,
      );
      widget.onSalvo();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
    if (mounted) setState(() => _salvando = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Feedback de Vídeo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _alunoIdCtrl,
              decoration: const InputDecoration(labelText: 'ID do Aluno'),
              keyboardType: TextInputType.number,
              enabled: widget.alunoIdPreenchido == null,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _exercicioIdCtrl,
              decoration: const InputDecoration(labelText: 'ID do Exercício'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _videoUrlCtrl,
              decoration: const InputDecoration(labelText: 'URL do Vídeo (Cloudinary, YouTube, etc)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioCtrl,
              decoration: const InputDecoration(labelText: 'Comentário Técnico'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
        ),
      ],
    );
  }
}
