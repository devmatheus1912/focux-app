import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../l10n/app_localizations.dart';

void avisarEntrouNoFim(
  BuildContext context, {
  required int alunoId,
  required String nome,
}) {
  final s = S.of(context);
  final limpo = nome.trim();
  FeedbackHelper.showSnackBar(
    context,
    SnackBar(
      content: Text(
        limpo.isEmpty ? s.treinosEntrouNoFimSemNome : s.treinosEntrouNoFim(limpo),
      ),
      backgroundColor: EagleTokens.good,
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: s.treinosVerRotina,
        textColor: Colors.white,
        onPressed: () => context.push(
          '/alunos/$alunoId/rotina',
          extra: limpo,
        ),
      ),
    ),
  );
}
