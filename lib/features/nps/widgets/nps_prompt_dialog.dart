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
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/data/aluno_onboarding_prefs.dart';
import '../data/nps_repository.dart';

/// Pergunta o NPS que o BFF liberou. Fechar sem responder adia por
/// [alunoNpsAdiadoDias] dias neste aparelho.
Future<void> showAlunoNpsPrompt(BuildContext context, WidgetRef ref) async {
  try {
    if (await isAlunoNpsAdiado() || !context.mounted) return;
    final repo = NpsRepository(ref.read(apiClientProvider));
    final respondeu = await showFxHomeSheet<bool>(
      context,
      builder: (ctx) => _NpsPromptSheet(repo: repo),
    );
    if (respondeu != true) await adiarAlunoNps();
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
      if (mounted) FxHomeSheetChrome.dismissAndPop(context, true);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
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
            title: s.npsPromptTitulo,
            subtitle: s.npsPromptSubtitulo,
            leading: Icon(Icons.favorite_outline, color: primary, size: 18),
          ),
          const SizedBox(height: TokensStrip.s4),
          Text(
            s.npsPromptNota(_score),
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
              s.npsPromptComentario,
              hint: s.npsPromptComentarioHint,
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          FxLiquidPrimaryButton(
            label: s.npsPromptEnviar,
            loading: _saving,
            onPressed: _saving ? null : _enviar,
          ),
          TextButton(
            onPressed:
                _saving ? null : () => FxHomeSheetChrome.dismissAndPop(context),
            child: Text(
              s.npsPromptDepois,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ),
        ],
      ),
    );
  }
}
