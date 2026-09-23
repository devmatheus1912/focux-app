/// Helpers for the S7 "registrar série" sheet.
///
/// Prescription range (`8-12`) stays read-only context from the personal.
/// The student logs the actual reps performed (integer count).
library;

import 'package:shared_preferences/shared_preferences.dart';

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

/// Last session matching set → prescription → previous set this session.
CheckinCurrentSetSeed checkinCurrentSetSeed({
  required ExecucaoExercicio ee,
  required int numero,
}) {
  ExecucaoSerie? byNumero(List<ExecucaoSerie> series, int n) {
    for (final s in series) {
      if (s.numero == n) return s;
    }
    return null;
  }

  final previous = byNumero(ee.seriesAnteriores, numero);
  if (previous != null &&
      (previous.cargaKg != null ||
          (previous.repeticoes != null &&
              previous.repeticoes!.trim().isNotEmpty &&
              !checkinIsPrescriptionRange(previous.repeticoes)))) {
    return CheckinCurrentSetSeed(
      cargaKg: previous.cargaKg ?? ee.cargaKg ?? ee.cargaAnteriorKg,
      reps: int.tryParse(checkinFirstRepsToken(previous.repeticoes) ?? ''),
    );
  }
  final prescReps = int.tryParse(checkinFirstRepsToken(ee.repeticoes) ?? '');
  final seedCarga = ee.cargaKg ?? ee.cargaAnteriorKg;
  if (seedCarga != null || prescReps != null) {
    return CheckinCurrentSetSeed(cargaKg: seedCarga, reps: prescReps);
  }
  if (ee.seriesDetalhes.isNotEmpty) {
    final last = ee.seriesDetalhes.last;
    return CheckinCurrentSetSeed(
      cargaKg: last.cargaKg,
      reps: int.tryParse(checkinFirstRepsToken(last.repeticoes) ?? '') ??
          prescReps,
    );
  }
  if (numero > 1) {
    final prior = byNumero(ee.seriesDetalhes, numero - 1);
    if (prior != null) {
      return CheckinCurrentSetSeed(
        cargaKg: prior.cargaKg,
        reps: int.tryParse(checkinFirstRepsToken(prior.repeticoes) ?? ''),
      );
    }
  }
  return const CheckinCurrentSetSeed();
}

String? checkinSeriePrescricaoHint(String? prescricacao) {
  final t = prescricacao?.trim() ?? '';
  if (t.isEmpty) return null;
  return 'Prescrição do personal: $t';
}

/// Plain-language RPE for students who don't know the acronym.
String checkinRpePlainLabel(int rpe) {
  final v = rpe.clamp(1, 10);
  return switch (v) {
    1 || 2 => 'Muito leve',
    3 || 4 => 'Leve',
    5 || 6 => 'Moderado',
    7 => 'Cansativo',
    8 => 'Pesado',
    9 => 'Muito pesado',
    _ => 'No limite',
  };
}

String checkinRpeValueLine(int rpe) => '$rpe · ${checkinRpePlainLabel(rpe)}';

const checkinRpeSectionTitle = 'Esforço sentido (RPE)';

const checkinRpeSectionHint =
    'RPE não é quantidade de reps. É o quão difícil a série pareceu '
    '(1 = muito leve, 10 = no limite). As reps feitas ficam no campo acima.';

String checkinRpeAlvoHint(int alvo) =>
    'Seu personal pediu esforço perto de $alvo (${checkinRpePlainLabel(alvo)}). '
    'Ajuste pelo que você sentiu nesta série.';
