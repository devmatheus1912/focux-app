import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../models/ia_progressao_carga_result.dart';
import '../utils/progressao_copy.dart';
import 'ia_expandable_copy.dart';
import 'ia_progressao_card_entrance.dart';
import 'ia_progressao_exercise_card.dart';
import 'ia_progressao_result_action_bar.dart';

/// Resultado da progressão: intro, um card por exercício, lembrete e ações.
class IaProgressaoResultView extends StatelessWidget {
  const IaProgressaoResultView({
    super.key,
    required this.result,
    this.alunoNome,
    this.onExportPdf,
    this.onReviewSuggestions,
    this.onReport,
  });

  final IaProgressaoCargaResult result;
  final String? alunoNome;
  final VoidCallback? onExportPdf;
  final VoidCallback? onReport;
  final VoidCallback? onReviewSuggestions;

  Future<void> _copy(BuildContext context) async {
    final geradoEm = result.geradoEm;
    await Clipboard.setData(
      ClipboardData(
        text: result.toPlainText(
          alunoNome: alunoNome,
          geradoLabel:
              geradoEm == null ? null : progressaoGeradoLabel(geradoEm),
        ),
      ),
    );
    if (!context.mounted) return;
    FeedbackHelper.showSuccess(context, 'Sugestão copiada.');
  }

  @override
  Widget build(BuildContext context) {
    final intro = result.intro;
    final footer = result.footer;
    final geradoEm = result.geradoEm;

    return AnimatedSwitcher(
      duration: fxMotionDuration(context),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Column(
        key: ValueKey(result.resposta),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              alunoNome == null
                  ? 'Sugestões por exercício'
                  : 'Sugestões para $alunoNome',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (geradoEm != null) ...[
            const SizedBox(height: 2),
            Text(
              progressaoGeradoLabel(geradoEm),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TokensStrip.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: TokensStrip.s2),
          if (intro != null) ...[
            IaExpandableCopy(text: intro, collapseLabel: 'Ver menos'),
            const SizedBox(height: TokensStrip.s3),
          ],
          ...result.exercises.asMap().entries.map(
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
          if (footer != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TokensStrip.textSecondary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
              ),
              child: IaExpandableCopy(
                text: footer,
                expandLabel: 'Ler lembrete completo',
                collapseLabel: 'Ocultar lembrete',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: TokensStrip.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: TokensStrip.s3),
          ],
          IaProgressaoResultActionBar(
            onCopy: () => _copy(context),
            onExportPdf: onExportPdf,
            onReviewSuggestions: onReviewSuggestions,
            pendingSuggestions: result.sugestoesRegistradas,
            onReport: onReport,
          ),
        ],
      ),
    );
  }
}
