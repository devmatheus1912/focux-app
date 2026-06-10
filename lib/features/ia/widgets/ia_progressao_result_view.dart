import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../models/ia_progressao_carga_result.dart';
import '../utils/ia_progressao_result_parser.dart';
import 'ia_carga_chip.dart';
import 'ia_expandable_copy.dart';
import 'ia_progressao_card_entrance.dart';
import 'ia_progressao_result_action_bar.dart';

/// Mobile-first rendering for IA progressão de carga responses.
class IaProgressaoResultView extends StatelessWidget {
  const IaProgressaoResultView({
    super.key,
    required this.result,
    this.alunoNome,
    this.onCopy,
    this.onExportPdf,
    this.onApplyTreino,
    this.onReviewSuggestions,
    this.showSectionTitle = true,
    this.showApplyTreino = true,
  });

  final IaProgressaoCargaResult result;
  final String? alunoNome;
  final VoidCallback? onCopy;
  final VoidCallback? onExportPdf;
  final VoidCallback? onApplyTreino;
  final VoidCallback? onReviewSuggestions;
  final bool showSectionTitle;
  final bool showApplyTreino;

  factory IaProgressaoResultView.fromMarkdown(
    String markdown, {
    Key? key,
    String? alunoNome,
    VoidCallback? onCopy,
    VoidCallback? onExportPdf,
    VoidCallback? onApplyTreino,
    VoidCallback? onReviewSuggestions,
    bool showSectionTitle = true,
    bool showApplyTreino = true,
  }) {
    return IaProgressaoResultView(
      key: key,
      result: IaProgressaoCargaResult.fromApi({'resposta': markdown}),
      alunoNome: alunoNome,
      onCopy: onCopy,
      onExportPdf: onExportPdf,
      onApplyTreino: onApplyTreino,
      onReviewSuggestions: onReviewSuggestions,
      showSectionTitle: showSectionTitle,
      showApplyTreino: showApplyTreino,
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsed = result.toParsed();
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
              showSectionTitle: showSectionTitle,
              showApplyTreino: showApplyTreino,
              onCopy: onCopy ?? () => _copyPlain(context, parsed),
              onExportPdf: onExportPdf,
              onApplyTreino: onApplyTreino,
              onReviewSuggestions: onReviewSuggestions,
            )
          : _FallbackMarkdown(
              key: ValueKey(result.resposta),
              markdown: result.resposta,
              onCopy: onCopy ?? () => _copyPlain(context, parsed),
              onExportPdf: onExportPdf,
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
    required this.showSectionTitle,
    required this.showApplyTreino,
    required this.onCopy,
    this.onExportPdf,
    this.onApplyTreino,
    this.onReviewSuggestions,
  });

  final IaProgressaoParsedResult parsed;
  final Color primary;
  final String? alunoNome;
  final bool showSectionTitle;
  final bool showApplyTreino;
  final VoidCallback onCopy;
  final VoidCallback? onExportPdf;
  final VoidCallback? onApplyTreino;
  final VoidCallback? onReviewSuggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (parsed.intro != null && parsed.intro!.isNotEmpty) ...[
          IaExpandableCopy(text: parsed.intro!),
          const SizedBox(height: TokensStrip.s3),
        ],
        if (showSectionTitle) ...[
          Semantics(
            header: true,
            child: Text(
              alunoNome == null
                  ? 'Sugestões por exercício'
                  : 'Sugestões para $alunoNome',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
        ],
        ...parsed.exercises.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s3),
            child: IaProgressaoCardEntrance(
              index: entry.key,
              child: _ExerciseCard(row: entry.value, primary: primary),
            ),
          ),
        ),
        if (parsed.footer != null && parsed.footer!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TokensStrip.textSecondary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
            ),
            child: IaExpandableCopy(
              text: parsed.footer!,
              expandLabel: 'Ler lembrete completo',
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: TokensStrip.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
        ],
        IaProgressaoResultActionBar(
          onCopy: onCopy,
          onExportPdf: onExportPdf,
          onApplyTreino: onApplyTreino,
          onReviewSuggestions: onReviewSuggestions,
          showApplyTreino: showApplyTreino,
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
          '${row.deltaLabel != null ? ' Variação ${row.deltaLabel}.' : ''}'
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: IaCargaChip(
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
                    child: IaCargaChip(
                      label: 'Sugerido',
                      valor: row.cargaSugerida,
                      color: primary,
                      deltaLabel: row.deltaLabel,
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
                        child: IaExpandableCopy(
                          text: row.justificativa,
                          expandLabel: 'Ler justificativa completa',
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

class _FallbackMarkdown extends StatelessWidget {
  const _FallbackMarkdown({
    super.key,
    required this.markdown,
    required this.onCopy,
    this.onExportPdf,
  });

  final String markdown;
  final VoidCallback onCopy;
  final VoidCallback? onExportPdf;

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
        const SizedBox(height: TokensStrip.s2),
        IaProgressaoResultActionBar(
          onCopy: onCopy,
          onExportPdf: onExportPdf,
          showApplyTreino: false,
        ),
      ],
    );
  }
}
