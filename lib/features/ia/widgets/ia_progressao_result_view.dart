import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../models/ia_progressao_carga_result.dart';
import '../utils/ia_progressao_result_parser.dart';
import 'ia_expandable_copy.dart';
import 'ia_progressao_card_entrance.dart';
import 'ia_progressao_exercise_card.dart';
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
    final parsed = _resolveParsed(result);
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
              pendingSuggestions: result.sugestoesRegistradas,
            )
          : _FallbackPlainText(
              key: ValueKey(result.resposta),
              text: parsed.toPlainText(),
              onCopy: onCopy ?? () => _copyPlain(context, parsed),
              onExportPdf: onExportPdf,
            ),
    );
  }

  /// Prefer API rows; re-parse markdown when empty (e.g. justificativa com "sugerida").
  static IaProgressaoParsedResult _resolveParsed(IaProgressaoCargaResult result) {
    final direct = result.toParsed();
    if (direct.hasStructuredRows) return direct;
    final reparsed = parseIaProgressaoMarkdown(result.resposta);
    if (!reparsed.hasStructuredRows) return direct;
    return IaProgressaoParsedResult(
      rawMarkdown: result.resposta,
      intro: result.intro ?? reparsed.intro,
      exercises: reparsed.exercises,
      footer: result.footer ?? reparsed.footer,
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
    this.pendingSuggestions = 0,
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
  final int pendingSuggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (parsed.intro != null && parsed.intro!.isNotEmpty) ...[
          IaExpandableCopy(
            text: parsed.intro!,
            collapseLabel: 'Ver menos contexto',
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
              child: IaProgressaoExerciseCard(
                exercicio: entry.value.exercicio,
                cargaAtual: entry.value.cargaAtual,
                cargaSugerida: entry.value.cargaSugerida,
                justificativa: entry.value.justificativa,
                deltaLabel: entry.value.deltaLabel,
              ),
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
              collapseLabel: 'Ocultar lembrete',
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
          pendingSuggestions: pendingSuggestions,
        ),
      ],
    );
  }
}

class _FallbackPlainText extends StatelessWidget {
  const _FallbackPlainText({
    super.key,
    required this.text,
    required this.onCopy,
    this.onExportPdf,
  });

  final String text;
  final VoidCallback onCopy;
  final VoidCallback? onExportPdf;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectableText(
          text,
          style: const TextStyle(fontSize: 14, height: 1.45),
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
