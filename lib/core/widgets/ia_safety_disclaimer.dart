import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Disclaimer de segurança exibido em TODAS as telas que geram
/// conteúdo via IA (treino, progressão, chat).
///
/// Atende requisito de Apple/Google Store: conteúdo de IA sinalizado
/// e revisado por profissional antes de chegar ao aluno.
/// Rodapé do PDF entregue ao aluno.
String iaPdfDisclaimer(String? personalNome) {
  final nome = personalNome?.trim() ?? '';
  final quem = nome.isEmpty ? 'pelo seu personal' : 'por $nome';
  return 'Plano revisado $quem. Gerado com apoio de IA.';
}

class IaSafetyDisclaimer extends StatelessWidget {
  final String? customText;
  final bool compact;

  const IaSafetyDisclaimer({super.key, this.customText, this.compact = false});

  /// Quem lê é o próprio profissional de Educação Física.
  static const defaultText =
      'Sugestões da IA são ponto de partida. Revise antes de aplicar ao aluno.';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = customText ?? defaultText;

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? EagleTokens.warn : EagleTokens.warnSoft)
            .withValues(alpha: isDark ? 0.22 : 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EagleTokens.warn.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 20,
            color: EagleTokens.warn,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
