import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../data/notificacoes_repository.dart';

class NotificacaoBadgeButton extends ConsumerWidget {
  final bool circular;
  final bool isDark;

  const NotificacaoBadgeButton({
    super.key,
    this.circular = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificacoesNaoLidasProvider).valueOrNull ?? 0;
    final primary = Theme.of(context).colorScheme.primary;
    final icon = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.notifications_none_rounded,
          color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
        ),
        if (count > 0)
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );

    if (!circular) {
      return IconButton(
        tooltip: 'Notificacoes',
        onPressed: () => context.push('/notificacoes'),
        icon: icon,
      );
    }

    return InkWell(
      onTap: () => context.push('/notificacoes'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          border: isDark ? null : Border.all(color: EagleTokens.line),
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }
}
