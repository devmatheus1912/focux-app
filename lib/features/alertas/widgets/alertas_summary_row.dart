import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';

class AlertasSummaryRow extends StatelessWidget {
  const AlertasSummaryRow({
    super.key,
    required this.altos,
    required this.medios,
    required this.saudaveis,
  });

  final int altos;
  final int medios;
  final int saudaveis;

  @override
  Widget build(BuildContext context) {
    final isDark = ShellChrome.of(context).isDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _Chip(
              value: '$altos',
              label: 'Score alto',
              bg: EagleTokens.semanticBadSoft(isDark: isDark),
              fg: EagleTokens.semanticBad(isDark: isDark),
              borderAlpha: isDark ? 0.2 : 0.15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Chip(
              value: '$medios',
              label: 'Score médio',
              bg: EagleTokens.semanticWarnSoft(isDark: isDark),
              fg: EagleTokens.semanticWarn(isDark: isDark),
              borderAlpha: isDark ? 0.2 : 0.15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Chip(
              value: '$saudaveis',
              label: 'Saudáveis',
              bg: EagleTokens.semanticGoodSoft(isDark: isDark),
              fg: EagleTokens.semanticGood(isDark: isDark),
              borderAlpha: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.value,
    required this.label,
    required this.bg,
    required this.fg,
    required this.borderAlpha,
  });

  final String value;
  final String label;
  final Color bg;
  final Color fg;
  final double borderAlpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withValues(alpha: borderAlpha)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
