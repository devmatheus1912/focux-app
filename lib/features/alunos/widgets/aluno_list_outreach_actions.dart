import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../constants/alunos_layout.dart';
import '../data/aluno_contact_utils.dart';
import '../providers/aluno_followup_provider.dart';

class AlunoListOutreachActions extends ConsumerWidget {
  const AlunoListOutreachActions({
    super.key,
    required this.alunoId,
    required this.displayName,
    required this.whatsappNumber,
    required this.hasWhatsapp,
    required this.emRisco,
    required this.primary,
    required this.isDark,
    required this.mute,
  });

  final int alunoId;
  final String displayName;
  final String whatsappNumber;
  final bool hasWhatsapp;
  final bool emRisco;
  final Color primary;
  final bool isDark;
  final Color mute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AlunoQuickActionIcon(
          compact: true,
          icon: Icons.forum_outlined,
          tooltip: 'Chat in-app',
          color: BrandPalette.sectionAction(primary, dark: isDark),
          onTap:
              () => context.push('/alunos/$alunoId/chat', extra: displayName),
        ),
        if (hasWhatsapp) ...[
          const SizedBox(width: 3),
          _AlunoQuickActionIcon(
            compact: true,
            icon: Icons.chat_rounded,
            tooltip: 'WhatsApp',
            color: EagleTokens.whatsapp,
            onTap:
                () => openAlunoWhatsappOutreach(
                  context,
                  displayName: displayName,
                  whatsappNumber: whatsappNumber,
                  emRisco: emRisco,
                ),
          ),
        ],
        const SizedBox(width: 3),
        _AlunoQuickActionIcon(
          compact: true,
          icon: Icons.snooze_rounded,
          tooltip: 'Adiar 24h',
          color: mute,
          onTap: () async {
            await ref.read(alunoFollowUpActionsProvider).snooze(alunoId);
            if (context.mounted) {
              FeedbackHelper.showSuccess(context, 'Lembrete adiado por 24h');
            }
          },
        ),
        const SizedBox(width: 3),
        _AlunoQuickActionIcon(
          compact: true,
          icon: Icons.check_circle_outline_rounded,
          tooltip: 'Contato feito',
          color: EagleTokens.good,
          onTap: () async {
            await ref
                .read(alunoFollowUpActionsProvider)
                .markContactDone(alunoId);
            if (context.mounted) {
              FeedbackHelper.showSuccess(context, 'Contato registrado');
            }
          },
        ),
      ],
    );
  }
}

class _AlunoQuickActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _AlunoQuickActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? AlunosLayout.touchTarget : AlunosLayout.touchTarget;
    final iconSize = compact ? 18.0 : 20.0;

    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: compact ? 0.1 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: iconSize, color: color),
          ),
        ),
      ),
    );
  }
}
