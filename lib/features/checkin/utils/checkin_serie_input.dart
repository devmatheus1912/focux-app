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
