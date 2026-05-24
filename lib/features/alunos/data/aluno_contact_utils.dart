import 'aluno_followup_store.dart';
import 'aluno_repository.dart';

/// Whether this aluno should appear in "Precisa contato hoje".
bool alunoPrecisaContatoHoje(
  Aluno aluno, {
  DateTime? snoozedUntil,
  DateTime? followUpDate,
  DateTime? now,
  int diasSemTreinoLimite = AlunoFollowUpStore.diasSemTreinoLimite,
}) {
  if (aluno.status != 'ATIVO') return false;

  final clock = now ?? DateTime.now();
  final snooze = snoozedUntil ?? aluno.snoozedUntilDate;
  if (snooze != null && snooze.isAfter(clock)) {
    return false;
  }

  final followDate = followUpDate ?? aluno.followUpDate;
  if (followDate != null) {
    final today = DateTime(clock.year, clock.month, clock.day);
    final followDay = DateTime(
      followDate.year,
      followDate.month,
      followDate.day,
    );
    if (!followDay.isAfter(today)) return true;
  }

  if (aluno.emRisco) return true;
  if (aluno.inadimplente || aluno.statusFinanceiro == 'INADIMPLENTE') {
    return true;
  }
  final dias = aluno.diasSemTreino ?? 0;
  if (dias >= diasSemTreinoLimite) return true;
  return false;
}

int alunoContatoPriorityBoost(
  Aluno aluno, {
  DateTime? now,
  int diasSemTreinoLimite = AlunoFollowUpStore.diasSemTreinoLimite,
}) {
  if (!alunoPrecisaContatoHoje(
    aluno,
    now: now,
    diasSemTreinoLimite: diasSemTreinoLimite,
  )) {
    return 0;
  }
  var boost = 4;
  final followDate = aluno.followUpDate;
  if (followDate != null) {
    final today = DateTime(now?.year ?? DateTime.now().year,
        now?.month ?? DateTime.now().month, now?.day ?? DateTime.now().day);
    final followDay = DateTime(
      followDate.year,
      followDate.month,
      followDate.day,
    );
    if (!followDay.isAfter(today)) boost += 3;
  }
  return boost;
}

String formatRiscoNivel(String? raw) {
  final value = (raw ?? '').trim().toUpperCase();
  if (value.isEmpty) return '—';
  return switch (value) {
    'ALTO' || 'HIGH' => 'Alto',
    'MEDIO' || 'MÉDIO' || 'MEDIUM' => 'Médio',
    'BAIXO' || 'LOW' => 'Baixo',
    _ => raw!.trim()[0].toUpperCase() + raw.trim().substring(1).toLowerCase(),
  };
}

String formatProximoContato(Aluno aluno) {
  final date = aluno.followUpDate;
  if (date == null) return 'Sem data';
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m';
}
