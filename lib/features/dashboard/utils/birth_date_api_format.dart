/// Normaliza data de nascimento digitada pelo aluno para ISO (AAAA-MM-DD).
String? normalizeBirthDateForApi(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;

  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return value;
  }

  final br = RegExp(r'^(\d{2})[/-](\d{2})[/-](\d{4})$').firstMatch(value);
  if (br != null) {
    return '${br.group(3)}-${br.group(2)}-${br.group(1)}';
  }

  if (RegExp(r'^\d{8}$').hasMatch(value)) {
    return '${value.substring(4, 8)}-${value.substring(2, 4)}-${value.substring(0, 2)}';
  }

  return value;
}

/// Exibe nascimento em BR (`19-12-1995`). API continua ISO no JSON.
String formatBirthDateForDisplay(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return '';

  if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(value)) return value;

  final slash = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value);
  if (slash != null) {
    return '${slash.group(1)}-${slash.group(2)}-${slash.group(3)}';
  }

  final iso = DateTime.tryParse(value);
  if (iso != null) {
    final dia = iso.day.toString().padLeft(2, '0');
    final mes = iso.month.toString().padLeft(2, '0');
    return '$dia-$mes-${iso.year}';
  }

  return value;
}
