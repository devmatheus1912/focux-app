part of 'chat_repository.dart';

/// Envio de mensagem. [idempotencyScope] vem do outbox do chat: a mesma
/// `Idempotency-Key` em reenvio faz o servidor responder `409` enquanto a
/// primeira tentativa processa e repetir a resposta original depois.
extension ChatRepositoryEnvio on ChatRepository {
  Future<ChatMsg> enviar(
    int alunoId,
    String conteudo,
    String remetente, {
    required String idempotencyScope,
    int? replyToMessageId,
    String? clientMessageId,
  }) => _postMensagem(
    '/api/chat/enviar',
    {'alunoId': alunoId, 'conteudo': conteudo, 'remetente': remetente},
    idempotencyScope: idempotencyScope,
    replyToMessageId: replyToMessageId,
    clientMessageId: clientMessageId,
  );

  Future<ChatMsg> enviarComoAluno(
    String conteudo, {
    required String idempotencyScope,
    int? replyToMessageId,
    String? clientMessageId,
  }) => _postMensagem(
    '/api/chat/aluno/enviar',
    {'conteudo': conteudo},
    idempotencyScope: idempotencyScope,
    replyToMessageId: replyToMessageId,
    clientMessageId: clientMessageId,
  );

  Future<ChatMsg> enviarMidiaComoAluno({
    required String conteudo,
    required String tipoMidia,
    required String midiaUrl,
    required String idempotencyScope,
    int? replyToMessageId,
    String? clientMessageId,
  }) => _postMensagem(
    '/api/chat/aluno/enviar',
    {'conteudo': conteudo, 'tipoMidia': tipoMidia, 'midiaUrl': midiaUrl},
    idempotencyScope: idempotencyScope,
    replyToMessageId: replyToMessageId,
    clientMessageId: clientMessageId,
  );

  Future<ChatMsg> enviarMidia({
    required int alunoId,
    required String conteudo,
    required String remetente,
    required String tipoMidia,
    required String midiaUrl,
    required String idempotencyScope,
    int? replyToMessageId,
    String? clientMessageId,
  }) => _postMensagem(
    '/api/chat/enviar',
    {
      'alunoId': alunoId,
      'conteudo': conteudo,
      'remetente': remetente,
      'tipoMidia': tipoMidia,
      'midiaUrl': midiaUrl,
    },
    idempotencyScope: idempotencyScope,
    replyToMessageId: replyToMessageId,
    clientMessageId: clientMessageId,
  );

  Future<ChatMsg> _postMensagem(
    String path,
    Map<String, dynamic> body, {
    required String idempotencyScope,
    int? replyToMessageId,
    String? clientMessageId,
  }) async {
    final r = await _dio.post(
      path,
      data: {
        ...body,
        'clientMessageId': clientMessageId ?? _clientMessageId(),
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      },
      options: ApiClient.idempotent(idempotencyScope),
    );
    return ChatMsg.fromJson(r.data);
  }
}
