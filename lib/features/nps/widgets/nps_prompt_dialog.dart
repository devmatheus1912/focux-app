import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/nps_repository.dart';

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
      builder: (ctx) => _NpsPromptSheet(repo: repo),
    );
  } catch (_) {}
}

class _NpsPromptSheet extends StatefulWidget {
  const _NpsPromptSheet({required this.repo});

  final NpsRepository repo;

  @override
  State<_NpsPromptSheet> createState() => _NpsPromptSheetState();
}

class _NpsPromptSheetState extends State<_NpsPromptSheet> {
  int _score = 8;
  final _comentario = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.repo.responder(
        score: _score,
        comentario: _comentario.text.trim(),
      );
      if (mounted) FxHomeSheetChrome.dismissAndPop(context);
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
    final chrome = ShellChrome.forBrightness(context, isDark);
    final primary = Theme.of(context).colorScheme.primary;

    return FxHomeSheetSurface(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          const SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Como está sua experiência?',
            subtitle: 'Uma nota rápida ajuda a melhorar o Focux.',
            leading: Icon(Icons.favorite_outline, color: primary, size: 18),
          ),
          const SizedBox(height: TokensStrip.s4),
          Text(
            'Nota: $_score',
            textAlign: TextAlign.center,
            style: FocuxHubTypography.cardTitle(color: chrome.ink),
          ),
          Slider(
            value: _score.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '$_score',
            onChanged:
                _saving ? null : (v) => setState(() => _score = v.round()),
          ),
          TextField(
            controller: _comentario,
            maxLines: 2,
            enabled: !_saving,
            textInputAction: TextInputAction.done,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: FxInputDeco.build(
              context,
              'Comentário',
              hint: 'Comentário (opcional)',
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          FxLiquidPrimaryButton(
            label: 'Enviar',
            loading: _saving,
            onPressed: _saving ? null : _enviar,
          ),
          TextButton(
            onPressed:
                _saving ? null : () => FxHomeSheetChrome.dismissAndPop(context),
            child: Text(
              'Depois',
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ),
        ],
      ),
    );
  }
}
