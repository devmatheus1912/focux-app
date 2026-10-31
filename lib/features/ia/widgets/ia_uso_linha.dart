import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../utils/ia_cota.dart';

/// Quanto de IA foi usado no mês e quando volta. Copiloto e Assinatura.
class IaUsoLinha extends StatelessWidget {
  const IaUsoLinha({
    super.key,
    required this.usado,
    required this.limite,
    this.agora,
  });

  final int usado;
  final int limite;

  /// Fixa a data em teste.
  final DateTime? agora;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tom = iaCotaTom(usado: usado, limite: limite);
    final cor = switch (tom) {
      IaCotaTom.normal => scheme.primary,
      IaCotaTom.atencao => chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn,
      IaCotaTom.esgotada => scheme.error,
    };
    final texto = iaCotaUsoTexto(
      usado: usado,
      limite: limite,
      agora: agora ?? DateTime.now(),
    );
    return Semantics(
      label: texto,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(texto, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
          const SizedBox(height: TokensStrip.s1),
          ClipRRect(
            borderRadius: BorderRadius.circular(TokensStrip.s1),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: limite <= 0 ? 0 : (usado / limite).clamp(0.0, 1.0),
              color: cor,
              backgroundColor: cor.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
