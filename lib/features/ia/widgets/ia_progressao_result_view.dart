import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../utils/ia_progressao_result_parser.dart';

/// Mobile-first rendering for IA progressão de carga responses.
class IaProgressaoResultView extends StatelessWidget {
  const IaProgressaoResultView({
    super.key,
    required this.markdown,
    this.alunoNome,
    this.onCopy,
    this.showCopyButton = true,
    this.showSectionTitle = true,
  });

  final String markdown;
  final String? alunoNome;
  final VoidCallback? onCopy;
  final bool showCopyButton;
  final bool showSectionTitle;

  @override
  Widget build(BuildContext context) {
    final parsed = parseIaProgressaoMarkdown(markdown);
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedSwitcher(
      duration: fxMotionDuration(context),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: parsed.hasStructuredRows
          ? _StructuredResult(
              key: ValueKey(parsed.toPlainText()),
              parsed: parsed,
              primary: primary,
              alunoNome: alunoNome,
              showCopyButton: showCopyButton,
              showSectionTitle: showSectionTitle,
              onCopy: onCopy ?? () => _copyPlain(context, parsed),
            )
          : _FallbackMarkdown(
              key: ValueKey(markdown),
              markdown: markdown,
              showCopyButton: showCopyButton,
              onCopy: onCopy ?? () => _copyPlain(context, parsed),
            ),
    );
  }

  static Future<void> _copyPlain(
    BuildContext context,
    IaProgressaoParsedResult parsed,
  ) async {
    await Clipboard.setData(ClipboardData(text: parsed.toPlainText()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sugestão copiada para a área de transferência.')),
    );
  }
}

class _StructuredResult extends StatelessWidget {
  const _StructuredResult({
    super.key,
    required this.parsed,
    required this.primary,
    this.alunoNome,
    required this.showCopyButton,
    required this.showSectionTitle,
    required this.onCopy,
  });

  final IaProgressaoParsedResult parsed;
  final Color primary;
  final String? alunoNome;
  final bool showCopyButton;
  final bool showSectionTitle;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (parsed.intro != null && parsed.intro!.isNotEmpty) ...[
          Text(
            parsed.intro!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: TokensStrip.textSecondary,
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
        ],
        if (showSectionTitle) ...[
          Semantics(
            header: true,
            child: Text(
              alunoNome == null
                  ? 'Sugestões por exercício'
                  : 'Sugestões para $alunoNome',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
        ],
        ...parsed.exercises.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s3),
            child: _ExerciseCard(row: row, primary: primary),
          ),
        ),
        if (parsed.footer != null && parsed.footer!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TokensStrip.textSecondary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
            ),
            child: Text(
              parsed.footer!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: TokensStrip.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
        ],
        if (showCopyButton)
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copiar sugestão'),
          ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.row, required this.primary});

  final IaProgressaoExerciseRow row;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${row.exercicio}. Carga atual ${row.cargaAtual}. '
          'Carga sugerida ${row.cargaSugerida}.'
          '${row.justificativa.isNotEmpty ? ' ${row.justificativa}' : ''}',
      child: Container(
        decoration: fxListCardDecoration(context, accent: primary),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.exercicio,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _CargaChip(
                      label: 'Atual',
                      valor: row.cargaAtual,
                      color: TokensStrip.textSecondary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded, color: primary, size: 20),
                  ),
                  Expanded(
                    child: _CargaChip(
                      label: 'Sugerido',
                      valor: row.cargaSugerida,
                      color: primary,
                    ),
                  ),
                ],
              ),
              if (row.justificativa.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TokensStrip.textSecondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: TokensStrip.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          row.justificativa,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: TokensStrip.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CargaChip extends StatelessWidget {
  const _CargaChip({
    required this.label,
    required this.valor,
    required this.color,
  });

  final String label;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Text(
            valor.isEmpty ? '—' : valor,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.25,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: TokensStrip.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FallbackMarkdown extends StatelessWidget {
  const _FallbackMarkdown({
    super.key,
    required this.markdown,
    required this.showCopyButton,
    required this.onCopy,
  });

  final String markdown;
  final bool showCopyButton;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MarkdownBody(
          data: markdown,
          selectable: true,
          shrinkWrap: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 14, height: 1.45),
            tableBody: const TextStyle(fontSize: 12),
          ),
        ),
        if (showCopyButton) ...[
          const SizedBox(height: TokensStrip.s2),
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copiar sugestão'),
          ),
        ],
      ],
    );
  }
}
