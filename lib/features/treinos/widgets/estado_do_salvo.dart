import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../l10n/app_localizations.dart';

/// Linha discreta abaixo do título: a ficha e o modelo gravam a cada mudança,
/// e isso precisa ficar visível ("Tudo salvo" / "Salvando…").
class EstadoDoSalvo extends StatelessWidget {
  const EstadoDoSalvo({super.key, required this.salvando});

  final bool salvando;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s1),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(
              salvando ? Icons.sync_rounded : Icons.cloud_done_outlined,
              size: 16,
              color: chrome.mute,
            ),
            const SizedBox(width: TokensStrip.s1),
            Text(
              salvando ? s.estadoSalvando : s.estadoTudoSalvo,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ],
        ),
      ),
    );
  }
}
