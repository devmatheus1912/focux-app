import 'package:flutter/material.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../data/nps_repository.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showNpsPromptIfNeeded(BuildContext context, WidgetRef ref) async {
  try {
    final repo = NpsRepository(ref.read(apiClientProvider));
    final deve = await repo.deveResponder();
    if (!deve || !context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _NpsDialog(repo: repo),
    );
  } catch (_) {}
}

class _NpsDialog extends StatefulWidget {
  final NpsRepository repo;
  const _NpsDialog({required this.repo});

  @override
  State<_NpsDialog> createState() => _NpsDialogState();
}

class _NpsDialogState extends State<_NpsDialog> {
  int _score = 8;
  final _comentario = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _saving = true);
    try {
      await widget.repo.responder(score: _score, comentario: _comentario.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Como está sua experiência?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Nota: $_score', style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _score.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '$_score',
            onChanged: (v) => setState(() => _score = v.round()),
          ),
          TextField(
            controller: _comentario,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Comentário (opcional)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Depois')),
        FilledButton(
          onPressed: _saving ? null : _enviar,
          child: _saving
              ? const FxLoading(size: 18, strokeWidth: 2)
              : const Text('Enviar'),
        ),
      ],
    );
  }
}
