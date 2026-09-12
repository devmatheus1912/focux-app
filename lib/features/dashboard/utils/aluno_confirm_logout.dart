import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../auth/providers/auth_provider.dart';

Future<void> confirmAlunoLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showFxConfirmSheet(
    context,
    title: 'Sair da conta',
    message: 'Deseja encerrar esta sessão neste aparelho?',
    confirmLabel: 'Sair',
    icon: Icons.logout_rounded,
    destructive: true,
  );
  if (confirmed != true || !context.mounted) return;
  await ref.read(authProvider.notifier).logout();
  if (!context.mounted) return;
  context.go('/login');
}
