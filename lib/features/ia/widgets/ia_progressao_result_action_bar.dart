import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';

class IaProgressaoResultActionBar extends StatelessWidget {
  const IaProgressaoResultActionBar({
    super.key,
    required this.onCopy,
    this.onExportPdf,
    this.onApplyTreino,
    this.onReviewSuggestions,
    this.showApplyTreino = true,
  });

  final VoidCallback onCopy;
  final VoidCallback? onExportPdf;
  final VoidCallback? onApplyTreino;
  final VoidCallback? onReviewSuggestions;
  final bool showApplyTreino;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showApplyTreino && onApplyTreino != null) ...[
          Semantics(
            button: true,
            label: 'Aplicar progressão no treino do aluno',
            child: FilledButton.icon(
              onPressed: onApplyTreino,
              icon: const Icon(Icons.fitness_center_rounded, size: 18),
              label: const Text('Aplicar no treino'),
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
        if (onReviewSuggestions != null) ...[
          const SizedBox(height: TokensStrip.s2),
          Semantics(
            button: true,
            label: 'Revisar sugestões pendentes de progressão',
            child: TextButton.icon(
              onPressed: onReviewSuggestions,
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text('Revisar sugestões pendentes'),
            ),
          ),
        ],
      ],
    );
  }
}
