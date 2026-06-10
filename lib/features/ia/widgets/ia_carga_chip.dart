import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';

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
    final isSuggested = label == 'Sugerido';
    final ink = isSuggested ? _suggestedInk(color) : color;
    final textTheme = Theme.of(context).textTheme;
    final valueStyle = (textTheme.titleSmall ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      height: 1.25,
      color: ink,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: clampedTextScaler(context, maxScale: 1.3),
      ),
      child: Semantics(
        label: '$label: ${valor.isEmpty ? 'não informado' : valor}'
            '${deltaLabel != null ? ', variação $deltaLabel' : ''}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSuggested ? ink.withValues(alpha: 0.12) : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSuggested ? ink.withValues(alpha: 0.55) : color.withValues(alpha: 0.32),
              width: isSuggested ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: TokensStrip.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                valor.isEmpty ? '—' : valor,
                textAlign: TextAlign.center,
                style: valueStyle,
              ),
              if (deltaLabel != null && isSuggested) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    deltaLabel!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Color _suggestedInk(Color primary) =>
      Color.lerp(primary, const Color(0xFF0B3D36), 0.42)!;
}
