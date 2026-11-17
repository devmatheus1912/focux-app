/// Helpers for the S7 "registrar série" sheet.
///
/// Prescription range (`8-12`) stays read-only context from the personal.
/// The student logs the actual reps performed (integer count).
library;

import 'serie_de_agora.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';
import '../data/checkin_repository.dart';

/// SharedPreferences flag: long RPE copy shown once, then only via `?`.
const checkinRpeHintSeenKey = 'checkin_rpe_hint_seen_v1';

/// Returns `true` the first time (caller should show the long hint), then
/// marks the key so later opens hide the paragraph.
Future<bool> checkinConsumeRpeFirstUseHint() async {
  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getBool(checkinRpeHintSeenKey) ?? false;
  if (!seen) {
    await prefs.setBool(checkinRpeHintSeenKey, true);
  }
  return !seen;
}

bool checkinIsPrescriptionRange(String? value) {
  final t = value?.trim() ?? '';
  if (t.isEmpty) return false;
  return RegExp(r'^\d+\s*[-–—]\s*\d+$').hasMatch(t);
}

/// Seed the editable reps field: last logged set, else first number of the
/// prescription (`8-12` → `8`). Never copy the range itself into the field.
String checkinSerieRepsSeed({
  required String? serieRepeticoes,
  required String? prescricacao,
}) {
  final logged = serieRepeticoes?.trim() ?? '';
  if (logged.isNotEmpty && !checkinIsPrescriptionRange(logged)) {
    return logged;
  }
  return checkinFirstRepsToken(prescricacao) ?? '';
}

String? checkinFirstRepsToken(String? prescription) {
  final t = prescription?.trim() ?? '';
  if (t.isEmpty) return null;
  final match = RegExp(r'(\d+)').firstMatch(t);
  return match?.group(1);
}

class CheckinCurrentSetSeed {
  const CheckinCurrentSetSeed({this.cargaKg, this.reps});

  final double? cargaKg;
  final int? reps;
}

/// O que os campos sugerem para a série [numero]: vem da [SerieDeAgora]
/// (a meta manda; a sessão passada só preenche a carga de quem conta).
CheckinCurrentSetSeed checkinCurrentSetSeed({
  required ExecucaoExercicio ee,
  required int numero,
}) {
  final sa = serieDeAgora(ee, numero: numero);
  return CheckinCurrentSetSeed(cargaKg: sa.cargaSugerida, reps: sa.repsSugeridas);
}

/// Uma série que falta no "Confirmar o resto", como a tela mostra.
typedef CheckinSerieRestante = ({int numero, double? cargaKg, int? reps});

/// "Confirmar o resto": o que a tela mostra em cada série que falta, para o
/// backend gravar exatamente isso. A série atual leva o rascunho do stepper
/// ([atual]); a seguinte sem fonte herda a anterior, como no registro série a
/// série.
List<CheckinSerieRestante> checkinSeriesRestantes(
  ExecucaoExercicio ee, {
  CheckinCurrentSetSeed? atual,
}) {
  final total = ee.series;
  if (total == null || total <= 0) return const [];
  final out = <CheckinSerieRestante>[];
  double? carga;
  int? reps;
  for (var n = ee.seriesFeitas + 1; n <= total; n++) {
    final seed =
        n == ee.seriesFeitas + 1 && atual != null
            ? atual
            : checkinCurrentSetSeed(ee: ee, numero: n);
    carga = seed.cargaKg ?? carga;
    reps = seed.reps ?? reps;
    out.add((numero: n, cargaKg: carga, reps: reps));
  }
  return out;
}

/// Carga e reps mexidos no stepper antes de registrar, por série.
class CheckinRascunhos {
  final Map<String, CheckinCurrentSetSeed> _porSerie = {};

  String _chave(ExecucaoExercicio ee) =>
      '${ee.treinoExercicioId}-${ee.seriesFeitas + 1}';

  CheckinCurrentSetSeed de(ExecucaoExercicio ee) =>
      _porSerie[_chave(ee)] ??
      checkinCurrentSetSeed(ee: ee, numero: ee.seriesFeitas + 1);

  void somarCarga(ExecucaoExercicio ee, double delta) {
    final atual = de(ee);
    _porSerie[_chave(ee)] = CheckinCurrentSetSeed(
      cargaKg: ((atual.cargaKg ?? 0) + delta).clamp(0, 500).toDouble(),
      reps: atual.reps,
    );
  }

  void somarReps(ExecucaoExercicio ee, int delta) {
    final atual = de(ee);
    _porSerie[_chave(ee)] = CheckinCurrentSetSeed(
      cargaKg: atual.cargaKg,
      reps: ((atual.reps ?? 0) + delta).clamp(0, 50).toInt(),
    );
  }

  void definirCarga(ExecucaoExercicio ee, double kg) {
    final atual = de(ee);
    _porSerie[_chave(ee)] = CheckinCurrentSetSeed(
      cargaKg: kg.clamp(0, 500).toDouble(),
      reps: atual.reps,
    );
  }

  void definirReps(ExecucaoExercicio ee, int reps) {
    final atual = de(ee);
    _porSerie[_chave(ee)] = CheckinCurrentSetSeed(
      cargaKg: atual.cargaKg,
      reps: reps.clamp(0, 50).toInt(),
    );
  }

  /// Envio recusado: o que foi digitado continua para a próxima tentativa.
  void manter(ExecucaoExercicio ee, {double? cargaKg, String? repeticoes}) {
    final atual = de(ee);
    _porSerie[_chave(ee)] = CheckinCurrentSetSeed(
      cargaKg: cargaKg ?? atual.cargaKg,
      reps: int.tryParse(checkinFirstRepsToken(repeticoes) ?? '') ?? atual.reps,
    );
  }
}

String? checkinSeriePrescricaoHint(S s, String? prescricacao) {
  final t = prescricacao?.trim() ?? '';
  if (t.isEmpty) return null;
  return s.checkinPrescricaoHint(t);
}

/// Plain-language RPE for students who don't know the acronym.
String checkinRpePlainLabel(S s, int rpe) {
  final v = rpe.clamp(1, 10);
  return switch (v) {
    1 || 2 => s.checkinRpeMuitoLeve,
    3 || 4 => s.checkinRpeLeve,
    5 || 6 => s.checkinRpeModerado,
    7 => s.checkinRpeCansativo,
    8 => s.checkinRpePesado,
    9 => s.checkinRpeMuitoPesado,
    _ => s.checkinRpeNoLimite,
  };
}

String checkinRpeValueLine(S s, int rpe) =>
    s.checkinRpeValor(rpe, checkinRpePlainLabel(s, rpe));

String checkinRpeAlvoHint(S s, int alvo) =>
    s.checkinRpeAlvoHint(alvo, checkinRpePlainLabel(s, alvo));
