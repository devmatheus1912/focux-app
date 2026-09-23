import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_a11y.dart';
import '../utils/aluno360_followup_dates.dart';
import '../utils/aluno360_operacao_logic.dart';
import 'aluno360_commitment_sheet.dart';

class Aluno360FollowUpCard extends StatelessWidget {
  const Aluno360FollowUpCard({
    super.key,
    required this.aluno,
    required this.isDark,
    this.compactContactPriority = false,
  });

  final Aluno aluno;
  final bool isDark;
  final bool compactContactPriority;

  String _formatDate(DateTime date) => alunoFollowUpDateLabel(date);

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _statusCaption({
    required DateTime? followUpDate,
    required bool isSnoozed,
    required DateTime? snoozedUntil,
  }) {
    if (compactContactPriority) {
      return alunoFollowUpCompactSubtitle(
        alunoNome: aluno.nome,
        followUpDate: followUpDate,
        isSnoozed: isSnoozed,
        snoozedUntil: snoozedUntil,
        formatDate: _formatDate,
      );
    }

    final parts = <String>[];
    if (aluno.ultimoContatoDate != null) {
      parts.add('Último contato: ${_formatDate(aluno.ultimoContatoDate!)}');
    }
    if (isSnoozed && snoozedUntil != null) {
      parts.add(
        'Adiado até ${_formatDate(snoozedUntil)} ${_formatTime(snoozedUntil)}',
      );
    } else if (followUpDate != null) {
      parts.add('Próximo contato: ${_formatDate(followUpDate)}');
    } else {
      parts.add('Agendar próximo contato · sincronizado com a nuvem');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = fxScreenMute(context);
    final followUpDate = aluno.followUpDate;
    final snoozedUntil = aluno.snoozedUntilDate;
    final isSnoozed =
        snoozedUntil != null && snoozedUntil.isAfter(DateTime.now());
    final compact = compactContactPriority;
    final caption = _statusCaption(
      followUpDate: followUpDate,
      isSnoozed: isSnoozed,
      snoozedUntil: snoozedUntil,
    );
    final openLabel =
        followUpDate == null && !isSnoozed
            ? 'Agendar follow-up'
            : 'Gerenciar follow-up';

    return Semantics(
      container: true,
      button: true,
      label: aluno360FollowUpSemantics(subtitle: caption, expanded: false),
      child: Column(
        key:
            compact
                ? const ValueKey('aluno360_followup_compact')
                : const ValueKey('aluno360_follow_up'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: compact ? 'Próximo contato' : 'Follow-up do personal',
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: FocuxHubTypography.bodyMuted(
              color: mute,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              style: Aluno360Layout.operacaoOutlinedButtonStyle(
                context,
                primary,
              ),
              onPressed:
                  () => showAluno360CommitmentSheet(
                    context,
                    aluno: aluno,
                    kind: Aluno360CommitmentKind.followUp,
                  ),
              child: Text(openLabel),
            ),
          ),
        ],
      ),
    );
  }
}
