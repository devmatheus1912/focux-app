import 'package:flutter/material.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_schedule.dart';

class AgendaNextBanner extends StatelessWidget {
  const AgendaNextBanner({
    super.key,
    required this.agendamento,
    required this.onTap,
    this.photoUrl,
  });

  final Agendamento agendamento;
  final VoidCallback onTap;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final title = agendaEventTitle(
      alunoNome: agendamento.alunoNome,
      titulo: agendamento.titulo,
    );
    final time = agendaHm(agendamento.inicio);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FxSettingsLayout.pageInset),
      child: FxSettingsGroup(
        header: 'Próximo',
        children: [
          FxSettingsTile(
            fxIcon: 'calendar',
            label: title,
            subtitle: 'Hoje · $time',
            value: time,
            highlight: true,
            showDivider: false,
            accessory: AlunoAvatar(
              name: title,
              photoUrl: photoUrl,
              variant: AlunoAvatarVariant.strip,
            ),
            semanticsLabel:
                'Próximo atendimento $time, $title. Abrir',
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class AgendaGapTile extends StatelessWidget {
  const AgendaGapTile({
    super.key,
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return FxSettingsTile(
      fxIcon: 'plus',
      label: label,
      subtitle: 'Horário livre',
      value: 'Encaixar',
      showDivider: showDivider,
      semanticsLabel: '$label. Encaixar horário',
      onTap: onTap,
    );
  }
}
