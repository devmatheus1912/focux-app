import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';

class CheckinWorkoutHeader extends StatelessWidget {
  final String treinoNome;
  final String contextLine;
  final VoidCallback onBack;
  final VoidCallback? onHelp;

  const CheckinWorkoutHeader({
    super.key,
    required this.treinoNome,
    required this.contextLine,
    required this.onBack,
    this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
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
            if (onHelp != null)
              FxHelpIconButton(
                tooltip: 'Dicas deste exercício',
                onTap: onHelp!,
              ),
            TextButton(onPressed: onBack, child: const Text('Sair')),
          ],
        ),
      ),
    );
  }
}
