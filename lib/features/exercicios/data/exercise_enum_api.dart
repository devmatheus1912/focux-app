/// Converte nomes camelCase do Dart para chaves enum do backend Java.
String dartEnumNameToBackendKey(String dartEnumName) {
  final buffer = StringBuffer();
  for (var i = 0; i < dartEnumName.length; i++) {
    final char = dartEnumName[i];
    final isUpper =
        char == char.toUpperCase() && char != char.toLowerCase();
    if (isUpper && i > 0) {
      buffer.write('_');
    }
    buffer.write(char.toUpperCase());
  }
  return buffer.toString();
}

/// Lê contagem de stats do picker (`porGrupo`).
int exercisePickerStatCount(Map<String, int> stats, String dartEnumName) {
  final backendKey = dartEnumNameToBackendKey(dartEnumName);
  return stats[dartEnumName] ?? stats[backendKey] ?? 0;
}

/// Parâmetro de query para filtros enum no backend.
String? enumQueryParam(Enum? value) =>
    value == null ? null : dartEnumNameToBackendKey(value.name);

/// CSV de enums para filtro multi (ex.: equipamentos do aluno).
String? enumSetQueryParam(Set<Enum> values) {
  if (values.isEmpty) return null;
  final keys =
      values.map((value) => dartEnumNameToBackendKey(value.name)).toList()
        ..sort();
  return keys.join(',');
}
