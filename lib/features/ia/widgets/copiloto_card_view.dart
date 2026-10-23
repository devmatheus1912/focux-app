import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/ia_copiloto_display.dart';

class CopilotoCardView extends StatelessWidget {
  const CopilotoCardView({
    super.key,
    required this.card,
    required this.modo,
    required this.onModo,
    required this.onAction,
    required this.onVerTarefas,
  });

  final CopilotoCard card;
  final String modo;
  final ValueChanged<String> onModo;
  final VoidCallback onAction;
  final VoidCallback onVerTarefas;

  static const _modos = ['Treino', 'Progressão'];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final mute = chrome.mute;
    final dark = chrome.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        0,
        FxSettingsLayout.pageInset,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.copilotoSobrancelha,
            style: FocuxHubTypography.eyebrow(context, color: mute),
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            card.titulo,
            style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            card.frase,
            style: FocuxHubTypography.bodyMuted(color: mute),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: TokensStrip.s4),
          FxLiquidPrimaryButton(label: card.botao, onPressed: onAction),
          const SizedBox(height: TokensStrip.s4),
          Row(
            children: [
              for (final item in _modos) ...[
                FxToggleChip(
                  label: item,
                  selected: item == modo,
                  isDark: dark,
                  filledWhenSelected: false,
                  onTap: () => onModo(item),
                ),
                if (item != _modos.last) const SizedBox(width: TokensStrip.s2),
              ],
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onVerTarefas,
              style: TextButton.styleFrom(
                foregroundColor: mute,
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                s.copilotoVerTarefas,
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
