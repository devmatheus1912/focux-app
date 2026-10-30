import '../data/chat_repository.dart';
import 'chat_remetente.dart';
import 'chat_system_event.dart';

/// Uma entrada do fio: mensagem humana (ou evento solto) ou treinos seguidos
/// numa linha só.
class ChatFioItem {
  const ChatFioItem(this.msgs);

  final List<ChatMsg> msgs;

  ChatMsg get primeira => msgs.first;
  ChatMsg get ultima => msgs.last;
  bool get grupo => msgs.length > 1;
}

bool _mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

ChatEventoTipo? _tipoDoEvento(ChatMsg msg) =>
    chatIsSistema(msg.remetente, msg.tipoMidia)
    ? formatChatSystemEvent(msg.conteudo).tipo
    : null;

/// O que aparece no fio. Sessão vazia nunca; treino só para o personal (o
/// aluno já tem o histórico); treinos seguidos no mesmo dia viram um item.
List<ChatFioItem> montarFioDoChat(
  List<ChatMsg> msgs, {
  required bool alunoMode,
}) {
  final fio = <ChatFioItem>[];
  for (final msg in msgs) {
    final tipo = _tipoDoEvento(msg);
    if (tipo == ChatEventoTipo.sessaoVazia) continue;
    if (alunoMode && tipo == ChatEventoTipo.treino) continue;
    final anterior = fio.isEmpty ? null : fio.last;
    if (tipo == ChatEventoTipo.treino &&
        anterior != null &&
        _tipoDoEvento(anterior.ultima) == ChatEventoTipo.treino &&
        _mesmoDia(anterior.ultima.enviadoEm, msg.enviadoEm)) {
      fio[fio.length - 1] = ChatFioItem([...anterior.msgs, msg]);
    } else {
      fio.add(ChatFioItem([msg]));
    }
  }
  return fio;
}
