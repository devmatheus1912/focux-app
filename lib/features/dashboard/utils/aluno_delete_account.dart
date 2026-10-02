import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/account/excluir_conta_flow.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../auth/providers/auth_provider.dart';

Future<void> confirmDeleteAlunoAccount(
  BuildContext context,
  WidgetRef ref,
) {
  return excluirContaFlow(
    context,
    dio: ref.read(apiClientProvider).dio,
    subtitulo:
        'Esta ação é irreversível. Seus dados pessoais serão anonimizados conforme a LGPD. '
        'Histórico financeiro ou operacional pode ser mantido pelo prazo legal.\n\n'
        'Digite sua senha (ou peça o código por e-mail) e EXCLUIR para confirmar.',
    aposExcluir: () async {
      await ref.read(authProvider.notifier).logout();
      if (!context.mounted) return;
      FeedbackHelper.showSuccess(context, 'Conta excluída com sucesso.');
      context.go('/login');
    },
  );
}
