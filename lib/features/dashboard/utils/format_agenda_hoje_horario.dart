/// Formats BE agenda `horario` (often ISO `2026-09-23T12:00`) for home UI.
///
/// Preferred: clock only when the slot is today (`12:00`); otherwise
/// `23 set · 12:00`. Never show raw ISO to the user.
String formatAgendaHojeHorario(
  String raw, {
  DateTime? now,
}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) {
    // Already human ("12:00") or unknown — pass through if short.
    if (trimmed.length <= 8 && !trimmed.contains('T')) return trimmed;
    return trimmed;
  }

  final local = parsed.isUtc ? parsed.toLocal() : parsed;
  final clock =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  final today = (now ?? DateTime.now());
  final sameDay =
      local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
  if (sameDay) return clock;

  const months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  return '${local.day} ${months[local.month - 1]} · $clock';
}
