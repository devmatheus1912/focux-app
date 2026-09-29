import '../data/chat_repository.dart';
import 'chat_outgoing_dedupe.dart';

/// Envio completo de uma mensagem (upload incluso). Reexecutar é seguro: o
/// servidor deduplica pelo `clientMessageId` capturado na operação.
typedef ChatSendOperation = Future<ChatMsg> Function();

enum ChatOutgoingStatus { sending, failed, sent, delivered, read }

/// Mensagens do próprio usuário que ainda não chegaram ao servidor. A bolha
/// otimista fica na conversa até o servidor confirmar; se o envio falha, ela
/// continua ali como "Não enviada" com a mesma operação para reenviar.
class ChatOutbox {
  final Map<String, ChatSendOperation> _operations = {};
  final Set<String> _failed = {};

  void track(String clientId, ChatSendOperation send) {
    _operations[clientId] = send;
    _failed.remove(clientId);
  }

  bool isFailed(String? clientId) =>
      clientId != null && _failed.contains(clientId);

  void forget(String clientId) {
    _operations.remove(clientId);
    _failed.remove(clientId);
  }

  /// Roda a operação rastreada. Sucesso tira a mensagem da fila local; falha
  /// a marca como não enviada e repassa o erro. `null` quando já foi
  /// esquecida (apagada ou confirmada por outro caminho).
  Future<ChatMsg?> dispatch(String clientId) async {
    final send = _operations[clientId];
    if (send == null) return null;
    _failed.remove(clientId);
    try {
      final msg = await send();
      forget(clientId);
      return msg;
    } catch (_) {
      if (_operations.containsKey(clientId)) _failed.add(clientId);
      rethrow;
    }
  }

  ChatOutgoingStatus statusOf(ChatMsg msg) {
    if (msg.id != null) {
      if (msg.readAt != null) return ChatOutgoingStatus.read;
      if (msg.deliveredAt != null) return ChatOutgoingStatus.delivered;
      return ChatOutgoingStatus.sent;
    }
    return isFailed(msg.clientMessageId)
        ? ChatOutgoingStatus.failed
        : ChatOutgoingStatus.sending;
  }

  /// Bolha não enviada com o mesmo texto: digitar de novo reenvia essa em vez
  /// de dizer que a mensagem "já foi enviada".
  ChatMsg? failedWithText(Iterable<ChatMsg> msgs, String text) {
    final normalized = normalizeOutgoingChatText(text);
    if (normalized.isEmpty) return null;
    for (final msg in msgs) {
      if (!isFailed(msg.clientMessageId)) continue;
      if (normalizeOutgoingChatText(msg.conteudo) == normalized) return msg;
    }
    return null;
  }
}

/// O servidor já tem a mensagem com esse `clientMessageId` (eco do WebSocket
/// ou recarga chegou antes da resposta do POST).
bool chatClientIdConfirmed(Iterable<ChatMsg> msgs, String clientId) =>
    msgs.any((m) => m.clientMessageId == clientId && m.id != null);

/// Recarga do histórico sem perder bolhas otimistas que o servidor ainda não
/// conhece — o texto de uma mensagem não enviada nunca some.
List<ChatMsg> keepUnsentOutgoing({
  required List<ChatMsg> server,
  required Iterable<ChatMsg> local,
}) {
  final known = {
    for (final msg in server)
      if (msg.clientMessageId != null) msg.clientMessageId!,
  };
  final unsent = local.where(
    (m) =>
        m.id == null &&
        m.clientMessageId != null &&
        !known.contains(m.clientMessageId),
  );
  if (unsent.isEmpty) return List.of(server);
  return [...server, ...unsent]
    ..sort((a, b) => a.enviadoEm.compareTo(b.enviadoEm));
}
