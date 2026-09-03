import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
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
    final chrome = ShellChrome.of(context);
    final title = agendaEventTitle(
      alunoNome: agendamento.alunoNome,
      titulo: agendamento.titulo,
    );
    final time = agendaHm(agendamento.inicio);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        0,
        FxSettingsLayout.pageInset,
        TokensStrip.s2,
      ),
      child: FxStripCard(
        emphasize: true,
        glowStrength: 0.06,
        onTap: onTap,
        semanticsLabel: 'Próximo atendimento $time, $title. Abrir',
        child: Row(
          children: [
            AlunoAvatar(
              name: title,
              photoUrl: photoUrl,
              variant: AlunoAvatarVariant.strip,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Próximo', style: FocuxHubTypography.chip(chrome.mute)),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.cardTitle(color: chrome.ink),
                  ),
                  Text(
                    'Hoje · $time',
                    style: FocuxHubTypography.bodyMuted(
                      color: chrome.mute,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: FocuxHubTypography.body(
                color: chrome.ink,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class AgendaGapTile extends StatelessWidget {
  const AgendaGapTile({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mute = ShellChrome.of(context).mute;
    return FxSatelliteListTile(
      title: label,
      subtitle: const Text('Horário livre'),
      trailing: Text(
        'Encaixar',
        style: FocuxHubTypography.bodyMuted(
          color: mute,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}
