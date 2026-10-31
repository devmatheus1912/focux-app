import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_schedule.dart';
import '../utils/agenda_status.dart';
import '../../../l10n/pt.dart';

class AgendaEventCard extends StatelessWidget {
  const AgendaEventCard({
    super.key,
    required this.agendamento,
    required this.onTap,
    this.photoUrl,
    this.emphasized = false,
    this.detalheExtra,
  });

  final Agendamento agendamento;
  final VoidCallback onTap;
  final String? photoUrl;
  final bool emphasized;

  /// Quanto falta, no próximo atendimento.
  final String? detalheExtra;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final title = agendaEventTitle(
      alunoNome: agendamento.alunoNome,
      titulo: agendamento.titulo,
    );
    final note = agendaEventSessionNote(agendamento.titulo);
    final atendimento = agendamento.statusAtendimento?.trim() ?? '';
    final status = agendaStatusLabel(
      atendimento.isEmpty ? agendamento.status : atendimento,
    );
    final time = agendaHm(agendamento.inicio);
    final subtitle = [
      if (detalheExtra case final extra?) extra,
      status,
      if (note != null && note.isNotEmpty) note,
    ].join(' · ');

    if (emphasized) {
      final sobre = fxPaletaSobreMarca(context);
      return Semantics(
        button: true,
        label: ptS.agendaProximoAtendimento(title, status, time),
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: TokensStrip.s2),
          child: GestureDetector(
            onTap: onTap,
            child: FxStripCard(
              marca: true,
              padding: const EdgeInsets.all(TokensStrip.s3),
              child: Row(
                children: [
                  AlunoAvatar(
                    name: title,
                    photoUrl: photoUrl,
                    variant: AlunoAvatarVariant.strip,
                  ),
                  const SizedBox(width: TokensStrip.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.cardTitle(color: sobre.ink),
                        ),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.bodyMuted(
                            color: sobre.mute,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: TokensStrip.s2),
                  Text(
                    time,
                    style: FocuxHubTypography.body(
                      color: sobre.ink,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
        onTap: onTap,
      ),
    );
  }
}
