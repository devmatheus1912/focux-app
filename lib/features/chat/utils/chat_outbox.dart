import 'package:dio/dio.dart';

import '../data/chat_repository.dart';
import 'chat_outgoing_dedupe.dart';

/// Envio completo de uma mensagem (upload incluso). Reexecutar é seguro: o
/// servidor deduplica pelo `clientMessageId` capturado na operação.
typedef ChatSendOperation = Future<ChatMsg> Function();

enum ChatOutgoingStatus { sending, failed, sent, delivered, read }

/// Onde está um envio rastreado: esquecido (confirmado ou descartado), ainda
/// em andamento ou parado como "Não enviada".
enum ChatSendPhase { gone, sending, failed }

/// Quantas vezes um `409` (primeira tentativa ainda em processamento no
/// servidor) é reconsultado antes de virar "Não enviada".
const chatMaxInFlightChecks = 3;
const chatInFlightRecheckDelay = Duration(seconds: 2);

/// `409` do filtro de idempotência: a mesma `Idempotency-Key` ainda está sendo
/// processada. A mensagem não falhou — só não terminou.
bool isChatSendInFlight(Object error) =>
    error is DioException && error.response?.statusCode == 409;

bool isChatMediaMessage(ChatMsg msg) =>
    msg.tipoMidia != null && msg.tipoMidia != 'TEXTO';

/// Responder e reagir exigem a mensagem salva no servidor.
bool chatCanReplyTo(ChatMsg msg) => msg.id != null && msg.deletedAt == null;

/// Upload + POST. O reenvio reaproveita a URL já enviada e só repete o POST.
ChatSendOperation chatMediaSendOperation({
  required Future<String> Function() upload,
  required Future<ChatMsg> Function(String mediaUrl) send,
}) {
  String? uploadedUrl;
  return () async {
    final url = uploadedUrl ??= await upload();
    return send(url);
  };
}

/// Mensagens do próprio usuário que ainda não chegaram ao servidor. A bolha
/// otimista fica na conversa até o servidor confirmar; se o envio falha, ela
/// continua ali como "Não enviada" com a mesma operação para reenviar.
class ChatOutbox {
  final Map<String, ChatSendOperation> _operations = {};
  final Set<String> _failed = {};
  final Map<String, int> _inFlightChecks = {};

  void track(String clientId, ChatSendOperation send) {
    _operations[clientId] = send;
    _failed.remove(clientId);
    _inFlightChecks.remove(clientId);
  }

  bool isFailed(String? clientId) =>
      clientId != null && _failed.contains(clientId);

  ChatSendPhase phaseOf(String clientId) {
    if (!_operations.containsKey(clientId)) return ChatSendPhase.gone;
    return _failed.contains(clientId)
        ? ChatSendPhase.failed
        : ChatSendPhase.sending;
  }

  void forget(String clientId) {
    _operations.remove(clientId);
    _failed.remove(clientId);
    _inFlightChecks.remove(clientId);
  }

  /// Mensagem que chegou do servidor (resposta, eco do WebSocket ou recarga)
  /// encerra o envio local com o mesmo `clientMessageId`.
  void forgetConfirmed(ChatMsg msg) {
    final clientId = msg.clientMessageId;
    if (msg.id != null && clientId != null) forget(clientId);
  }

  /// Roda a operação rastreada. Sucesso tira a mensagem da fila local. Falha
  /// a marca como não enviada — exceto `409` em andamento, que segue
  /// "Enviando…" até [chatMaxInFlightChecks]. O erro é sempre repassado.
  /// `null` quando já foi esquecida (confirmada por outro caminho ou apagada).
  Future<ChatMsg?> dispatch(String clientId) async {
    final send = _operations[clientId];
    if (send == null) return null;
    if (_failed.remove(clientId)) _inFlightChecks.remove(clientId);
    try {
      final msg = await send();
      forget(clientId);
      return msg;
    } catch (error) {
      if (_operations.containsKey(clientId) && !_keepSending(clientId, error)) {
        _failed.add(clientId);
      }
      rethrow;
    }
  }

  bool _keepSending(String clientId, Object error) {
    if (!isChatSendInFlight(error)) return false;
    final checks = (_inFlightChecks[clientId] ?? 0) + 1;
    _inFlightChecks[clientId] = checks;
    return checks <= chatMaxInFlightChecks;
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
      if (msg.id != null || !isFailed(msg.clientMessageId)) continue;
      if (normalizeOutgoingChatText(msg.conteudo) == normalized) return msg;
    }
    return null;
  }
}

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
