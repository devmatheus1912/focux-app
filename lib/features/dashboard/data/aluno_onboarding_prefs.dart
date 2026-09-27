import 'package:shared_preferences/shared_preferences.dart';

/// Guarda a segunda-feira da semana em que o aluno abriu a agenda.
const kAlunoAgendaReviewedKey = 'aluno_agenda_reviewed_week_v2';
const _kLegacyAgendaReviewedKey = 'aluno_agenda_reviewed_v1';

/// Chaves que não podem sobreviver ao logout em aparelho compartilhado.
const alunoOnboardingPrefKeys = [
  kAlunoAgendaReviewedKey,
  _kLegacyAgendaReviewedKey,
];

/// Segunda-feira da semana de [now], em `yyyy-MM-dd`.
String alunoAgendaSemanaKey(DateTime now) {
  final segunda = DateTime(
    now.year,
    now.month,
    now.day - (now.weekday - DateTime.monday),
  );
  final mm = segunda.month.toString().padLeft(2, '0');
  final dd = segunda.day.toString().padLeft(2, '0');
  return '${segunda.year}-$mm-$dd';
}

Future<bool> isAlunoAgendaReviewed({DateTime? now}) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(kAlunoAgendaReviewedKey) ==
      alunoAgendaSemanaKey(now ?? DateTime.now());
}

Future<void> markAlunoAgendaReviewed({DateTime? now}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    kAlunoAgendaReviewedKey,
    alunoAgendaSemanaKey(now ?? DateTime.now()),
  );
  await prefs.remove(_kLegacyAgendaReviewedKey);
}
