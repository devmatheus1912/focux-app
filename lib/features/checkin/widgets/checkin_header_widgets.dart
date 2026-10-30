import 'package:flutter/material.dart';

import '../../../core/widgets/fx_tonal_button.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/checkin_execucao_display.dart';

class CheckinWorkoutHeader extends StatelessWidget {
  final String treinoNome;
  final String contextLine;
  final VoidCallback onBack;
  final VoidCallback? onHelp;

  /// Abre as ações do exercício (ajustar, confirmar séries, finalizar).
  final VoidCallback? onMais;

  const CheckinWorkoutHeader({
    super.key,
    required this.treinoNome,
    required this.contextLine,
    required this.onBack,
    this.onHelp,
    this.onMais,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          TokensStrip.s3,
          TokensStrip.s3,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    treinoNome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.sectionTitle(
                      context,
                      color: chrome.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contextLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxTypography.bodySmall(color: chrome.mute),
                  ),
                ],
              ),
            ),
            // "?", "⋯" e "Sair": mesma altura (48), mesmo estilo tonal, sem sombra.
            if (onHelp != null)
              _BotaoDoCabecalho(
                tooltip: s.checkinDicasExercicio,
                icone: Icons.help_outline_rounded,
                onPressed: onHelp!,
              ),
            if (onMais != null) ...[
              const SizedBox(width: TokensStrip.s1),
              _BotaoDoCabecalho(
                tooltip: s.checkinMais,
                icone: Icons.more_horiz_rounded,
                onPressed: onMais!,
              ),
            ],
            const SizedBox(width: TokensStrip.s1),
            SizedBox(
              height: checkinExecutionControlMin,
              child: Center(
                child: FxTonalButton(
                  label: s.checkinSair,
                  icon: Icons.logout_rounded,
                  compact: true,
                  onPressed: onBack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão de ícone tonal do cabeçalho da execução (48, sem sombra).
class _BotaoDoCabecalho extends StatelessWidget {
  const _BotaoDoCabecalho({required this.tooltip, required this.icone, required this.onPressed});

  final String tooltip;
  final IconData icone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).colorScheme.primary;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: brand.withValues(alpha: 0.08),
        side: BorderSide(color: brand.withValues(alpha: 0.35)),
      ),
      icon: Icon(icone, color: brand),
    );
  }
}
