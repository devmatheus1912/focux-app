/// Title-cases a person name for display ("thales silva" → "Thales Silva").
/// Siglas de produto (IA, PIX, MFA…) ficam em caixa alta.
String fxTitleCaseName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Aluno';

  const keepUpper = {
    'ia',
    'pix',
    'mfa',
    'api',
    'bff',
    'fcm',
    'crm',
    'rpe',
    'lgpd',
    'sms',
    'otp',
  };

  return trimmed
      .split(RegExp(r'\s+'))
      .map((part) {
        if (part.isEmpty) return part;
        final lower = part.toLowerCase();
        if (keepUpper.contains(lower)) return lower.toUpperCase();
        return part[0].toUpperCase() + part.substring(1).toLowerCase();
      })
      .join(' ');
}

/// Returns the 2-letter initials for a full name.
///
/// Design spec: first letter of first + last word.
/// "Matheus Ribeiro" → "MR"  |  "Ana" → "AN" (double first)  |  "" → "?"
String fxInitials(String nome) {
  final parts = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final w = parts[0];
    return w.length >= 2 ? w.substring(0, 2).toUpperCase() : w[0].toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

/// Returns a human-readable relative time string for a DateTime.
/// "agora", "5 min", "2h", "ontem", "3 dias", etc.
String fxTimeAgo(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return 'agora';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays == 1) return 'ontem';
  if (diff.inDays < 7) return '${diff.inDays} dias';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} sem';

  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$day/$month';
}

const _monthsFull = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

const _monthsShort = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];

/// "4 de maio de 2026"
String fxDateFull(DateTime d) =>
    '${d.day} de ${_monthsFull[d.month - 1]} de ${d.year}';

/// "04/05"
String fxDateShort(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// "Mai 2026"
String fxMonthYear(DateTime d) => '${_monthsShort[d.month - 1]} ${d.year}';

/// "hoje às 18:39" · "ontem às 09:05" · "12/09 às 18:39" · "12/09/2025 às 18:39"
String fxDateTimeLabel(DateTime d, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final hm =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(ref.year, ref.month, ref.day);
  final diffDays = today.difference(day).inDays;
  if (diffDays == 0) return 'hoje às $hm';
  if (diffDays == 1) return 'ontem às $hm';
  final date =
      d.year == ref.year ? fxDateShort(d) : '${fxDateShort(d)}/${d.year}';
  return '$date às $hm';
}

/// ISO do backend → [fxDateTimeLabel]; vazio se não parsear.
String fxDateTimeLabelFromIso(String? raw, {DateTime? now}) {
  final parsed = DateTime.tryParse(raw ?? '');
  if (parsed == null) return '';
  return fxDateTimeLabel(parsed.isUtc ? parsed.toLocal() : parsed, now: now);
}
