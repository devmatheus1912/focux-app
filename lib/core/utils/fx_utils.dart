/// Returns the 2-letter initials for a full name.
///
/// Design spec: first letter of first + last word.
/// "Matheus Ribeiro" → "MR"  |  "Ana" → "AN" (double first)  |  "" → "?"
String fxInitials(String nome) {
  final parts =
      nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final w = parts[0];
    return w.length >= 2
        ? w.substring(0, 2).toUpperCase()
        : w[0].toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
