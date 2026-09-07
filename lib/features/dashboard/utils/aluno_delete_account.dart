import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../auth/providers/auth_provider.dart';

Future<void> confirmDeleteAlunoAccount(
  BuildContext context,
  WidgetRef ref,
) async {
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final confirmed = await showFxFormSheet(
    context,
    title: 'Excluir conta',
    subtitle:
        'Esta ação é irreversível. Seus dados pessoais serão anonimizados conforme a LGPD. '
        'Histórico financeiro ou operacional pode ser mantido pelo prazo legal.\n\n'
        'Digite sua senha e EXCLUIR para confirmar.',
    icon: Icons.delete_forever_outlined,
    confirmLabel: 'Excluir definitivamente',
    destructive: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: passwordCtrl,
          obscureText: true,
          decoration: FxInputDeco.build(context, 'Senha atual'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: confirmCtrl,
          decoration: FxInputDeco.build(context, 'Digite EXCLUIR'),
        ),
      ],
    ),
  );

  final senha = passwordCtrl.text;
  final confirmacao = confirmCtrl.text.trim();
  passwordCtrl.dispose();
  confirmCtrl.dispose();

  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(apiClientProvider).dio.delete(
      '/api/lgpd/me/delete',
      data: {'senha': senha, 'confirmacao': confirmacao},
    );
    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
    FeedbackHelper.showSuccess(context, 'Conta excluída com sucesso.');
    context.go('/login');
  } catch (e) {
    if (!context.mounted) return;
    FeedbackHelper.showError(context, friendlyError(e));
  }
}
