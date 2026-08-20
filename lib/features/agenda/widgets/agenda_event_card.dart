import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_schedule.dart';
import '../utils/agenda_status.dart';

class AgendaEventCard extends StatelessWidget {
  const AgendaEventCard({
    super.key,
    required this.agendamento,
    required this.onTap,
    this.photoUrl,
    this.emphasized = false,
  });

  final Agendamento agendamento;
  final VoidCallback onTap;
  final String? photoUrl;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final sColor = agendaStatusColor(
      agendamento.status,
      isDark: chrome.isDark,
      primary: primary,
    );
    final title = agendaEventTitle(
      alunoNome: agendamento.alunoNome,
      titulo: agendamento.titulo,
    );
    final note = agendaEventSessionNote(agendamento.titulo);
    final showEnd = agendamento.fim.isAfter(agendamento.inicio);

    return Semantics(
      button: true,
      label:
          'Atendimento $title, ${agendaStatusLabel(agendamento.status)}, ${agendaHm(agendamento.inicio)}',
      child: Material(
        color: fxTransparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: fxListCardDecoration(
              context,
              accent: emphasized ? primary : sColor,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Column(
                    children: [
                      Text(
                        agendaHm(agendamento.inicio),
                        style: AppTypography.mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: showEnd ? 14 : 20,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      if (showEnd)
                        Text(
                          agendaHm(agendamento.fim),
                          style: AppTypography.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: chrome.mute,
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AlunoAvatar(
                    name: title,
                    photoUrl: photoUrl,
                    variant: AlunoAvatarVariant.strip,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: FocuxHubTypography.cardTitle(color: chrome.ink),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (note != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.bodyMuted(
                            color: chrome.mute,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: sColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            agendaStatusLabel(agendamento.status),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: sColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color:
                        chrome.isDark
                            ? chrome.ink.withValues(alpha: 0.08)
                            : primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
