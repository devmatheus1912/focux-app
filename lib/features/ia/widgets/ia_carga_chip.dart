import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';

/// Shared Atual/Sugerido chip used in progressão IA and aceitar screens.
class IaCargaChip extends StatelessWidget {
  const IaCargaChip({
    super.key,
    required this.label,
    required this.valor,
    required this.color,
    this.deltaLabel,
  });

  final String label;
  final String valor;
  final Color color;
  final String? deltaLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final valueStyle = (textTheme.titleSmall ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      height: 1.25,
      color: color,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        children: [
          Text(
            valor.isEmpty ? '—' : valor,
            textAlign: TextAlign.center,
            style: valueStyle,
          ),
          if (deltaLabel != null && label == 'Sugerido') ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                deltaLabel!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: TokensStrip.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
