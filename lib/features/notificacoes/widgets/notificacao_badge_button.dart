import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/shell_chrome.dart';
import '../data/notificacoes_repository.dart';

/// Header notification bell — TOKENS STRIP chrome, reacts to theme changes.
class NotificacaoBadgeButton extends ConsumerWidget {
  const NotificacaoBadgeButton({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificacoesNaoLidasProvider).valueOrNull ?? 0;

    return ShellHeaderIconButton(
      icon: 'bell',
      size: size,
      badgeCount: count,
      tooltip: 'Notificações',
      onTap: () => context.push('/notificacoes'),
    );
  }
}
