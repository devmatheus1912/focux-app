import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/feedback_helper.dart';
import '../../../l10n/app_localizations.dart';

void avisarEntrouNoFim(
  BuildContext context, {
  required int alunoId,
  required String nome,
}) {
  final s = S.of(context);
  final limpo = nome.trim();
  FeedbackHelper.showSuccessAction(
    context,
    limpo.isEmpty ? s.treinosEntrouNoFimSemNome : s.treinosEntrouNoFim(limpo),
    actionLabel: s.treinosVerRotina,
    onAction: () => context.push('/alunos/$alunoId/rotina', extra: limpo),
  );
}
