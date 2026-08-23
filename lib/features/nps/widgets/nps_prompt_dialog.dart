import 'package:flutter/material.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../data/nps_repository.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showNpsPromptIfNeeded(
  BuildContext context,
  WidgetRef ref, {
  bool? deveResponder,
}) async {
  if (deveResponder == false) return;
  try {
    final repo = NpsRepository(ref.read(apiClientProvider));
    final deve = deveResponder ?? await repo.deveResponder();
    if (!deve || !context.mounted) return;
    await showFxHomeSheet<void>(
      context,
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
      await widget.repo.responder(
        score: _score,
        comentario: _comentario.text.trim(),
      );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return FxHomeSheetSurface(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          const SizedBox(height: 16),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Como está sua experiência?',
            leading: Icon(Icons.favorite_outline, color: primary, size: 18),
          ),
          const SizedBox(height: 16),
          Text(
            'Nota: $_score',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
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
            decoration: FxInputDeco.build(
              context,
              'Comentário',
              hint: 'Comentário (opcional)',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _enviar,
            child:
                _saving
                    ? const FxLoading(size: 18, strokeWidth: 2)
                    : const Text('Enviar'),
          ),
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Depois'),
          ),
        ],
      ),
    );
  }
}
