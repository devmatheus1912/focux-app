import 'package:flutter/material.dart';

import '../../../core/widgets/fx_action_row.dart';
import '../../../l10n/app_localizations.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_followup_dates.dart';
import 'aluno360_commitment_sheet.dart';

/// "Próximo contato": a data do retorno (ou o convite para agendar) e um
/// verbo. Abre a folha de follow-up.
class Aluno360FollowUpCard extends StatelessWidget {
  const Aluno360FollowUpCard({super.key, required this.aluno});

  final Aluno aluno;

  /// "Agendado para 12/11 · Último contato: 02/11". Função pura para teste.
  static String legenda(S s, Aluno aluno, {DateTime? agora}) {
    final followUp = aluno.followUpDate;
    final adiado = aluno.snoozedUntilDate;
    final emAdiamento =
        adiado != null && adiado.isAfter(agora ?? DateTime.now());
    final partes = <String>[
      if (emAdiamento)
        s.alunoResumoContatoAdiado(alunoFollowUpDateLabel(adiado))
      else if (followUp != null)
        s.alunoResumoContatoAgendado(alunoFollowUpDateLabel(followUp))
      else
        s.alunoResumoContatoSemData,
      if (aluno.ultimoContatoDate != null)
        s.alunoResumoUltimoContato(
          alunoFollowUpDateLabel(aluno.ultimoContatoDate!),
        ),
    ];
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final semData =
        aluno.followUpDate == null &&
        !(aluno.snoozedUntilDate?.isAfter(DateTime.now()) ?? false);
    return FxActionRow(
      key: const ValueKey('aluno360_follow_up'),
      leading: Icons.event_outlined,
      titulo: s.alunoResumoContatoTitulo,
      motivo: legenda(s, aluno),
      verbo: semData
          ? s.alunoResumoContatoAgendar
          : s.alunoResumoContatoGerenciar,
      onTap: () => showAluno360CommitmentSheet(
        context,
        aluno: aluno,
        kind: Aluno360CommitmentKind.followUp,
      ),
    );
  }
}
