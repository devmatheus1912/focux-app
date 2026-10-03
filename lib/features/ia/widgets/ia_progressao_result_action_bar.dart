import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/progressao_copy.dart';

class IaProgressaoResultActionBar extends StatelessWidget {
  const IaProgressaoResultActionBar({
    super.key,
    required this.onCopy,
    this.onExportPdf,
    this.onReviewSuggestions,
    this.pendingSuggestions = 0,
    this.onReport,
  });

  final VoidCallback onCopy;
  final VoidCallback? onReport;
  final VoidCallback? onExportPdf;
  final VoidCallback? onReviewSuggestions;
  final int pendingSuggestions;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onReviewSuggestions != null && pendingSuggestions > 0) ...[
          Semantics(
            button: true,
            label: progressaoAceitarSemanticsLabel(pendingSuggestions),
            child: FilledButton.icon(
              onPressed: onReviewSuggestions,
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text(progressaoRevisarAplicar),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
        ],
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Copiar sugestão de progressão',
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copiar'),
                ),
              ),
            ),
            if (onExportPdf != null) ...[
              const SizedBox(width: TokensStrip.s2),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Exportar progressão em PDF',
                  child: OutlinedButton.icon(
                    onPressed: onExportPdf,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('PDF'),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (onReport != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.flag_outlined, size: 16),
              label: Text(S.of(context).moderacaoDenunciarIa),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
