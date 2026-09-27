import 'package:shared_preferences/shared_preferences.dart';

/// Início (ISO) do próximo horário que o aluno já viu ao abrir a agenda.
const kAlunoAgendaVistaKey = 'aluno_agenda_vista_v3';
const _kLegacyAgendaKeys = [
  'aluno_agenda_reviewed_week_v2',
  'aluno_agenda_reviewed_v1',
];

/// Dia (`yyyy-MM-dd`) em que o aluno fechou o NPS sem responder.
const kAlunoNpsAdiadoEmKey = 'aluno_nps_adiado_em_v1';
const alunoNpsAdiadoDias = 7;

/// Chaves que não podem sobreviver ao logout em aparelho compartilhado.
const alunoOnboardingPrefKeys = [
  kAlunoAgendaVistaKey,
  ..._kLegacyAgendaKeys,
  kAlunoNpsAdiadoEmKey,
];

bool alunoNpsAdiado(String? adiadoEm, DateTime now) {
  final dia = adiadoEm == null ? null : DateTime.tryParse(adiadoEm);
  if (dia == null) return false;
  final hoje = DateTime(now.year, now.month, now.day);
  return hoje.difference(dia).inDays < alunoNpsAdiadoDias;
}

Future<bool> isAlunoNpsAdiado({DateTime? now}) async {
  final prefs = await SharedPreferences.getInstance();
  return alunoNpsAdiado(
    prefs.getString(kAlunoNpsAdiadoEmKey),
    now ?? DateTime.now(),
  );
}

Future<void> adiarAlunoNps({DateTime? now}) async {
  final prefs = await SharedPreferences.getInstance();
  final d = now ?? DateTime.now();
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  await prefs.setString(kAlunoNpsAdiadoEmKey, '${d.year}-$mm-$dd');
}

/// O aluno já viu este horário: um horário novo (ou o seguinte) volta a pedir.
bool alunoAgendaVista(String? vista, DateTime? proximoInicio) =>
    proximoInicio != null && vista == proximoInicio.toIso8601String();

Future<String?> readAlunoAgendaVista() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(kAlunoAgendaVistaKey);
}

Future<void> markAlunoAgendaReviewed(DateTime? proximoInicio) async {
  if (proximoInicio == null) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kAlunoAgendaVistaKey, proximoInicio.toIso8601String());
  for (final legado in _kLegacyAgendaKeys) {
    await prefs.remove(legado);
  }
}
