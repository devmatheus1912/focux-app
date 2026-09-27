/// Prazo soft da atribuição aluno↔treino — orientação, nunca bloqueia check-in.
abstract final class TreinoAtribuicaoPrazo {
  TreinoAtribuicaoPrazo._();

  static DateTime? parseIsoDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String toIsoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isAtrasado(DateTime? dataFim, {DateTime? today}) {
    if (dataFim == null) return false;
    final fim = dateOnly(dataFim);
    final t = dateOnly(today ?? DateTime.now());
    return fim.isBefore(t);
  }

  /// Chip do aluno: `Até 01/10`, `Vence hoje`, `Atrasado · até 01/10`.
  static String? chipLabel(DateTime? dataFim, {DateTime? today}) {
    if (dataFim == null) return null;
    final fim = dateOnly(dataFim);
    final t = dateOnly(today ?? DateTime.now());
    final fmt =
        '${fim.day.toString().padLeft(2, '0')}/${fim.month.toString().padLeft(2, '0')}';
    if (fim.isBefore(t)) return 'Atrasado · até $fmt';
    if (fim == t) return 'Vence hoje';
    return 'Até $fmt';
  }
}
