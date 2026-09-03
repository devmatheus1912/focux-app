import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
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
    final title = agendaEventTitle(
      alunoNome: agendamento.alunoNome,
      titulo: agendamento.titulo,
    );
    final note = agendaEventSessionNote(agendamento.titulo);
    final status = agendaStatusLabel(agendamento.status);
    final time = agendaHm(agendamento.inicio);
    final subtitle = [
      status,
      if (note != null && note.isNotEmpty) note,
    ].join(' · ');

    return Semantics(
      button: true,
      label: 'Atendimento $title, $status, $time',
      child: FxSatelliteListTile(
        title: title,
        subtitle: Text(subtitle),
        leading: AlunoAvatar(
          name: title,
          photoUrl: photoUrl,
          variant: AlunoAvatarVariant.strip,
        ),
        trailing: Text(
          time,
          style: FocuxHubTypography.body(
            color: chrome.ink,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
        accent: emphasized ? primary : null,
        onTap: onTap,
      ),
    );
  }
}
