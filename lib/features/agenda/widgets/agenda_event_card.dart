import 'package:flutter/material.dart';

import '../../../core/widgets/fx_settings_tile.dart';
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
    this.showDivider = true,
  });

  final Agendamento agendamento;
  final VoidCallback onTap;
  final String? photoUrl;
  final bool emphasized;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
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

    return FxSettingsTile(
      fxIcon: 'calendar',
      label: title,
      subtitle: subtitle,
      value: time,
      numeric: true,
      highlight: emphasized,
      showDivider: showDivider,
      accessory: AlunoAvatar(
        name: title,
        photoUrl: photoUrl,
        variant: AlunoAvatarVariant.strip,
      ),
      semanticsLabel:
          'Atendimento $title, $status, $time',
      onTap: onTap,
    );
  }
}
