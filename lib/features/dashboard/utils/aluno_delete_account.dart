import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/account/excluir_conta_flow.dart';
import '../../../core/account/excluir_conta_sheet.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../auth/providers/auth_provider.dart';

Future<void> confirmDeleteAlunoAccount(
  BuildContext context,
  WidgetRef ref,
) {
  return excluirContaFlow(
    context,
    dio: ref.read(apiClientProvider).dio,
    papel: ExcluirContaPapel.aluno,
    aposExcluir: () async {
      await ref.read(authProvider.notifier).logout();
      if (!context.mounted) return;
      FeedbackHelper.showSuccess(context, 'Conta excluída com sucesso.');
      context.go('/login');
    },
  );
}
