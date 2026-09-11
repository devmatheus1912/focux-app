/// Helpers for the S7 "registrar série" sheet.
///
/// Prescription range (`8-12`) stays read-only context from the personal.
/// The student logs the actual reps performed (integer count).
library;

bool checkinIsPrescriptionRange(String? value) {
  final t = value?.trim() ?? '';
  if (t.isEmpty) return false;
  return RegExp(r'^\d+\s*[-–—]\s*\d+$').hasMatch(t);
}

/// Seed the editable reps field: last logged set, else empty.
/// Never seed with a prescription range like `8-12`.
String checkinSerieRepsSeed({
  required String? serieRepeticoes,
  required String? prescricacao,
}) {
  final logged = serieRepeticoes?.trim() ?? '';
  if (logged.isNotEmpty && !checkinIsPrescriptionRange(logged)) {
    return logged;
  }
  // Prescription is context only — leave blank for the student to fill.
  return '';
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
