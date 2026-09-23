import '../data/chat_text_formatter.dart';

/// Evento de sistema no fio (treino registrado, etc.) — não é bolha humana.
class ChatSystemEventView {
  final String title;
  final String? detail;

  const ChatSystemEventView({required this.title, this.detail});

  String get threadLabel =>
      detail == null || detail!.isEmpty ? title : '$title · $detail';
}

final _treinoRegistrado = RegExp(
  r'^treino\s+registrado:\s*(.+?)\.\s*(\d+)\s*/\s*(\d+)\s*s[eé]ries?\b',
  caseSensitive: false,
);

final _respondaNoChat = RegExp(
  r'\s*responda\s+no\s+chat\b.*$',
  caseSensitive: false,
);

/// Compacta o dump do backend em título + detalhe. Sem CTA de “responda no chat”.
ChatSystemEventView formatChatSystemEvent(String raw) {
  final text = formatChatTextForDisplay(raw);
  if (text.isEmpty) {
    return const ChatSystemEventView(title: 'Atualização do treino');
  }

  final treino = _treinoRegistrado.firstMatch(text);
  if (treino != null) {
    final nome = treino.group(1)!.trim();
    final feitas = treino.group(2);
    final total = treino.group(3);
    return ChatSystemEventView(
      title: 'Treino registrado',
      detail: '$nome · $feitas de $total séries',
    );
  }

  final cleaned = text.replaceFirst(_respondaNoChat, '').trim();
  if (cleaned.isEmpty) {
    return const ChatSystemEventView(title: 'Atualização do treino');
  }

  final dot = cleaned.indexOf('.');
  if (dot > 8 && dot < cleaned.length - 1) {
    final title = cleaned.substring(0, dot).trim();
    final detail = cleaned
        .substring(dot + 1)
        .trim()
        .replaceAll(RegExp(r'\.\s*$'), '');
    if (title.isNotEmpty) {
      return ChatSystemEventView(
        title: title,
        detail: detail.isEmpty ? null : detail,
      );
    }
  }

  return ChatSystemEventView(title: cleaned);
}
