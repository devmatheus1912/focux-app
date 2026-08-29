/// Ajustes incrementais de volume — regra pura para steppers do sheet.
int adjustPrescriptionSeries(int value, int delta) =>
    (value + delta).clamp(1, 20);

int adjustPrescriptionRestSeconds(int value, int deltaSeconds) =>
    (value + deltaSeconds).clamp(15, 300);

int parsePrescriptionInt(String raw, {required int fallback}) {
  final parsed = int.tryParse(raw.trim());
  return parsed ?? fallback;
}
