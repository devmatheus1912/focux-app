import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../utils/ia_copiloto_display.dart';
import '../../../core/utils/pt_br_display.dart';

/// Chip sticky S1 após gerar — paridade [DashboardPrioritiesOverlay].
/// Overlay flutuante (não barra `bottomNavigationBar` / S3–S5).
/// O pai posiciona no Stack; scroll reserva folga para não cobrir Insights.
class IaCopilotResultActionBar extends StatelessWidget {
  const IaCopilotResultActionBar({
    super.key,
    required this.brand,
    required this.onPrimary,
    required this.onMore,
    this.primaryLabel,
  });

  final Color brand;
  final String? primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onMore;

  /// Folga de scroll quando a barra está visível (botão + padding + nav).
  static const double scrollReserve = 96;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? EagleTokens.darkBg : TokensStrip.pageBg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s2,
          TokensStrip.s2,
          TokensStrip.s2 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Row(
          children: [
            Expanded(
              child: FxLiquidPrimaryButton(
                label: primaryLabel ?? iaCopilotoCriarTarefaLabel(),
                onPressed: onPrimary,
              ),
            ),
            IconButton(
              tooltip: S.of(context).copilotoMenuTitulo,
              icon: Icon(Icons.more_horiz_rounded, color: brand),
              onPressed: onMore,
            ),
          ],
        ),
      ),
    );
  }
}

class IaCopilotHeaderStatus extends StatelessWidget {
  const IaCopilotHeaderStatus({
    super.key,
    required this.dark,
    required this.brand,
    required this.ink,
    this.quotaLabel = 'Pronto',
  });

  final bool dark;
  final Color brand;
  final Color ink;
  final String quotaLabel;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, dark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: chrome.headerAction(radius: 999),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: brand, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            quotaLabel,
            style: TextStyle(
              color: ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class IaCopilotGenerationStatus extends StatelessWidget {
  const IaCopilotGenerationStatus({
    super.key,
    required this.gerando,
    required this.gerado,
    required this.elapsedMs,
    required this.ink,
    required this.mute,
    required this.wash,
  });

  final bool gerando;
  final bool gerado;
  final int elapsedMs;
  final Color ink;
  final Color mute;
  final Color wash;

  @override
  Widget build(BuildContext context) {
    final elapsed =
        elapsedMs >= 1000
            ? '${formatBrDecimal(elapsedMs / 1000)}s'
            : '${elapsedMs}ms';

    // Pós-gerar: linha compacta — não empurra Insights abaixo do fold (§9 S1 / pilar 13).
    if (gerado && !gerando) {
      return Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: EagleTokens.copilotSuccess,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pronto para revisão',
              style: TextStyle(
                color: ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (elapsedMs > 0)
            Text(
              elapsed,
              style: TextStyle(
                color: mute,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
        ],
      );
    }

    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: EagleTokens.copilotSuccess,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gerando recomendações...',
                  style: TextStyle(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: wash,
              valueColor: const AlwaysStoppedAnimation(
                EagleTokens.copilotSuccess,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IaCopilotMetaChip extends StatelessWidget {
  const IaCopilotMetaChip({
    super.key,
    required this.label,
    required this.icon,
    required this.brand,
    required this.ink,
    required this.line,
  });

  final String label;
  final IconData icon;
  final Color brand;
  final Color ink;
  final Color line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 7, 10, 7),
      decoration: BoxDecoration(
        color: brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: brand),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: ink,
              fontSize: 11.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
