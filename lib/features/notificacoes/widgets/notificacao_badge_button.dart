import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/shell_chrome.dart';
import '../data/notificacoes_repository.dart';

String notificacaoBadgeTooltip(int count) {
  if (count <= 0) return 'Notificações';
  if (count > 9) return '9 ou mais notificações';
  if (count == 1) return '1 notificação';
  return '$count notificações';
}

/// Header notification bell — TOKENS STRIP chrome, reacts to theme changes.
class NotificacaoBadgeButton extends ConsumerWidget {
  const NotificacaoBadgeButton({
    super.key,
    this.size = 38,
    this.countOverride,
  });

  final double size;
  /// Preferência do BFF `/home` — unifica badge sem sidecar.
  final int? countOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(notificacoesNaoLidasProvider).valueOrNull;
    final count = countOverride ?? live ?? 0;

    return ShellHeaderIconButton(
      icon: 'bell',
      size: size,
      badgeCount: count,
      tooltip: notificacaoBadgeTooltip(count),
      onTap: () => context.push('/notificacoes'),
    );
  }
}
