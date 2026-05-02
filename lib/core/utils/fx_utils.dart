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
