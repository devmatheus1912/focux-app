String formatChatTextForDisplay(String raw) {
  final trimmed = normalizeChatText(raw);
  if (trimmed.isEmpty) return '';

  final lines = trimmed
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trimRight())
      .toList(growable: false);
  if (lines.length < 2 || lines.length.isOdd) {
    return lines.join('\n').trim();
  }

  final midpoint = lines.length ~/ 2;
  final firstHalf = lines.take(midpoint).toList(growable: false);
  final secondHalf = lines.skip(midpoint).toList(growable: false);
  for (var i = 0; i < midpoint; i++) {
    if (firstHalf[i].trim() != secondHalf[i].trim()) {
      return lines.join('\n').trim();
    }
  }

  return firstHalf.join('\n').trim();
}

String normalizeChatText(String raw) {
  return raw
      .replaceAll(RegExp(r'\*\*|__|`'), '')
      .replaceAll(RegExp(r'^\s*[-•]\s*', multiLine: true), '')
      .trim();
}
