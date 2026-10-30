import '../data/chat_text_formatter.dart';

enum ChatEventoTipo { treino, evolucao, sessaoVazia, outro }

/// Evento de sistema no fio (treino registrado, etc.) — não é bolha humana.
class ChatSystemEventView {
  final String title;
  final String? detail;
  final ChatEventoTipo tipo;

  /// Evolução: uma linha por exercício.
  final List<String> linhas;

  const ChatSystemEventView({
    required this.title,
    this.detail,
    this.tipo = ChatEventoTipo.outro,
    this.linhas = const [],
  });

  /// A linha no fio e na prévia: o detalhe já diz tudo.
  String get threadLabel => tipo == ChatEventoTipo.treino
      ? detail!
      : detail == null || detail!.isEmpty
      ? title
      : '$title · $detail';
}

final _treinoRegistrado = RegExp(
  r'^treino\s+registrado:\s*(.+?)\.\s*(\d+)\s*/\s*(\d+)\s*s[eé]ries?\b',
  caseSensitive: false,
);

final _feitoSemSeries = RegExp(
  r'^treino\s+registrado:\s*(.+?)\.\s*feito\s+sem\s+registrar',
  caseSensitive: false,
);

final _sessaoVazia = RegExp(r'sem\s+s[eé]ries\s+registradas', caseSensitive: false);

final _evoluiu = RegExp(r'voc[eê]\s+evoluiu', caseSensitive: false);

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

  final jaFiz = _feitoSemSeries.firstMatch(text);
  if (jaFiz != null) {
    return ChatSystemEventView(
      title: 'Treino registrado',
      detail: '${jaFiz.group(1)!.trim()} · sem registrar séries',
      tipo: ChatEventoTipo.treino,
    );
  }

  if (_sessaoVazia.hasMatch(text)) {
    return const ChatSystemEventView(
      title: 'Sessão sem séries',
      tipo: ChatEventoTipo.sessaoVazia,
    );
  }

  if (_evoluiu.hasMatch(text)) {
    final linhas = [
      for (final linha in raw.split('\n'))
        if (linha.trimLeft().startsWith('- '))
          linha.trimLeft().substring(2).trim(),
    ];
    return ChatSystemEventView(
      title: linhas.isEmpty
          ? 'Evoluiu no treino'
          : linhas.length == 1
          ? 'Evoluiu em 1 exercício'
          : 'Evoluiu em ${linhas.length} exercícios',
      tipo: ChatEventoTipo.evolucao,
      linhas: linhas,
    );
  }

  final treino = _treinoRegistrado.firstMatch(text);
  if (treino != null) {
    final nome = treino.group(1)!.trim();
    final feitas = treino.group(2);
    final total = treino.group(3);
    return ChatSystemEventView(
      title: 'Treino registrado',
      detail: '$nome · $feitas de $total séries',
      tipo: ChatEventoTipo.treino,
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
