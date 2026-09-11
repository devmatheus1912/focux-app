import 'package:shared_preferences/shared_preferences.dart';

const kAlunoAgendaReviewedKey = 'aluno_agenda_reviewed_v1';

Future<bool> isAlunoAgendaReviewed() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kAlunoAgendaReviewedKey) ?? false;
}

Future<void> markAlunoAgendaReviewed() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kAlunoAgendaReviewedKey, true);
}
