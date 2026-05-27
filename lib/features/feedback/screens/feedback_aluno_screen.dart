import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/feedback_video_repository.dart';

class FeedbackAlunoScreen extends ConsumerStatefulWidget {
  const FeedbackAlunoScreen({super.key});

  @override
  ConsumerState<FeedbackAlunoScreen> createState() => _FeedbackAlunoScreenState();
}

class _FeedbackAlunoScreenState extends ConsumerState<FeedbackAlunoScreen> {
  List<FeedbackVideo> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await FeedbackVideoRepository(ref.read(apiClientProvider)).meus();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enviar() async {
    final urlCtrl = TextEditingController();
    final comentCtrl = TextEditingController();
    final exCtrl = TextEditingController(text: '0');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar form check'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL do vídeo')),
            TextField(controller: exCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ID exercício')),
            TextField(controller: comentCtrl, decoration: const InputDecoration(labelText: 'Comentário')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar')),
        ],
      ),
    );
    if (ok != true || urlCtrl.text.trim().isEmpty) return;

    try {
      await FeedbackVideoRepository(ref.read(apiClientProvider)).enviarMeu(
        videoUrl: urlCtrl.text.trim(),
        exercicioId: int.tryParse(exCtrl.text) ?? 0,
        comentario: comentCtrl.text.trim(),
      );
      if (mounted) {
        FeedbackHelper.showSnackBar(context, const SnackBar(content: Text('Vídeo enviado! Análise IA em andamento.')));
        _load();
      }
    } catch (e) {
      if (mounted) FeedbackHelper.showSnackBar(context, SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FxShellScaffold(
      appBar: FxShellAppBar(title: 'Form check', onBack: () => context.pop()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _enviar,
        icon: const Icon(Icons.videocam_outlined),
        label: const Text('Enviar vídeo'),
      ),
      body: _loading
          ? const Center(child: FxLoading())
          : ListView.separated(
              padding: const EdgeInsets.all(TokensStrip.s4),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final f = _items[i];
                return Card(
                  child: ExpansionTile(
                    title: Text('Exercício #${f.exercicioId}'),
                    subtitle: Text(f.statusAnalise ?? 'PENDENTE'),
                    children: [
                      if (f.aiScore != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Score IA: ${f.aiScore}/100', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                        ),
                      if (f.aiAnalise != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(f.aiAnalise!),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
