import '../data/chat_text_formatter.dart';

const _stopWords = {
  'oi',
  'me',
  'com',
  'para',
  'pelo',
  'pela',
  'seu',
  'sua',
  'que',
  'uma',
  'um',
  'agora',
  'quando',
  'fizer',
  'combinado',
  'responde',
  'aqui',
  'ok',
  'plano',
};

String normalizeOutgoingChatText(String value) {
  return normalizeChatText(
    value,
  ).replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
}

/// Mesmo texto (ou a mesma ação do Copiloto reescrita) já está entre as
/// mensagens recentes do próprio remetente.
bool isRecentDuplicateOutgoing(String text, Iterable<String> recentMine) {
  final normalized = normalizeOutgoingChatText(text);
  if (normalized.isEmpty) return false;
  for (final conteudo in recentMine) {
    final sent = normalizeOutgoingChatText(conteudo);
    if (sent == normalized || _looksLikeSameCopilotAction(sent, normalized)) {
      return true;
    }
  }
  return false;
}

bool _looksLikeSameCopilotAction(String a, String b) {
  final aWords = _meaningfulWords(a);
  final bWords = _meaningfulWords(b);
  if (aWords.length < 5 || bWords.length < 5) return false;
  final overlap = aWords.intersection(bWords).length;
  final smaller = aWords.length < bWords.length ? aWords.length : bWords.length;
  return overlap >= 5 && overlap / smaller >= 0.62;
}

Set<String> _meaningfulWords(String value) {
  return value
      .split(RegExp(r'[^a-z0-9áéíóúâêôãõç]+', caseSensitive: false))
      .where((word) => word.length > 2 && !_stopWords.contains(word))
      .toSet();
}
