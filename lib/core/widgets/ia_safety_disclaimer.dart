import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Disclaimer de segurança exibido em TODAS as telas que geram
/// conteúdo via IA (treino, dieta, progressão, chat).
///
/// Atende requisito de Apple/Google Store:
///   - Apps que geram recomendações de saúde precisam informar
///     que o conteúdo não substitui profissional qualificado.
class IaSafetyDisclaimer extends StatelessWidget {
  final String? customText;
  final bool compact;

  const IaSafetyDisclaimer({super.key, this.customText, this.compact = false});

  static const _defaultText =
      'As sugestões geradas por IA são apenas orientações iniciais e '
      'não substituem a avaliação de um profissional de Educação Física '
      'ou Nutrição. Sempre consulte um especialista antes de adotar '
      'qualquer plano de treino ou dieta.';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = customText ?? _defaultText;

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
        color: (isDark ? Colors.amber.shade900 : Colors.amber.shade50)
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.amber.shade700 : Colors.amber.shade200),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 20,
            color: Colors.amber.shade700,
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
