import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
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
    this.compact = false,
  });

  final int alunoId;
  final String displayName;
  final String whatsappNumber;
  final bool hasWhatsapp;
  final bool emRisco;
  final Color primary;
  final bool isDark;
  final Color mute;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = BrandPalette.sectionAction(primary, dark: isDark);
    final primaryContact = hasWhatsapp
        ? _AlunoQuickActionIcon(
          compact: compact,
          icon: Icons.chat_rounded,
          tooltip: 'WhatsApp',
          color: action,
          onTap:
              () => openAlunoWhatsappOutreach(
                context,
                displayName: displayName,
                whatsappNumber: whatsappNumber,
                emRisco: emRisco,
              ),
        )
        : _AlunoQuickActionIcon(
          compact: compact,
          icon: Icons.forum_outlined,
          tooltip: 'Chat in-app',
          color: action,
          onTap:
              () => context.push('/alunos/$alunoId/chat', extra: displayName),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        primaryContact,
        if (!compact && hasWhatsapp) ...[
          const SizedBox(width: 3),
          _AlunoQuickActionIcon(
            compact: compact,
            icon: Icons.forum_outlined,
            tooltip: 'Chat in-app',
            color: action,
            onTap:
                () => context.push('/alunos/$alunoId/chat', extra: displayName),
          ),
        ],
        if (!compact) ...[
          const SizedBox(width: 3),
          _AlunoQuickActionIcon(
            compact: compact,
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
        ],
        const SizedBox(width: 3),
        _AlunoQuickActionIcon(
          compact: compact,
          icon: Icons.check_circle_outline_rounded,
          tooltip: 'Contato feito',
          color: action,
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
    final visual = compact ? 36.0 : 40.0;
    final iconSize = compact ? 17.0 : 20.0;

    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: AlunosLayout.touchTarget,
          height: AlunosLayout.touchTarget,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: Container(
                width: visual,
                height: visual,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: compact ? 0.1 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: iconSize, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
