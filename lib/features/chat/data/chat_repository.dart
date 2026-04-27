import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class ChatReaction {
  final String emoji;
  final int total;
  final bool mine;

  const ChatReaction({
    required this.emoji,
    required this.total,
    required this.mine,
  });

  factory ChatReaction.fromJson(Map<String, dynamic> j) => ChatReaction(
        emoji: j['emoji'] as String? ?? '',
        total: j['total'] as int? ?? 0,
        mine: j['mine'] as bool? ?? false,
      );
}

class ChatMsg {
  final int? id;
  final int? alunoId;
  final String remetente;
  final String conteudo;
  final DateTime enviadoEm;
  final String? tipoMidia;
  final String? midiaUrl;
  final String? clientMessageId;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final int? replyToMessageId;
  final String? replyToConteudo;
  final String? replyToRemetente;
  final List<ChatReaction> reactions;

  ChatMsg({
    this.id,
    this.alunoId,
    required this.remetente,
    required this.conteudo,
    required this.enviadoEm,
    this.tipoMidia,
    this.midiaUrl,
    this.clientMessageId,
    this.deliveredAt,
    this.readAt,
    this.replyToMessageId,
    this.replyToConteudo,
    this.replyToRemetente,
    this.reactions = const [],
  });

  factory ChatMsg.fromJson(Map<String, dynamic> j) => ChatMsg(
        id: j['id'] as int?,
        alunoId: j['alunoId'] as int?,
        remetente: j['remetente'] as String,
        conteudo: j['conteudo'] as String,
        enviadoEm: DateTime.parse(j['enviadoEm'] as String),
        tipoMidia: j['tipoMidia'] as String?,
        midiaUrl: j['midiaUrl'] as String?,
        clientMessageId: j['clientMessageId'] as String?,
        deliveredAt: j['deliveredAt'] != null
            ? DateTime.tryParse(j['deliveredAt'].toString())
            : null,
        readAt: j['readAt'] != null
            ? DateTime.tryParse(j['readAt'].toString())
            : null,
        replyToMessageId: j['replyToMessageId'] as int?,
        replyToConteudo: j['replyToConteudo'] as String?,
        replyToRemetente: j['replyToRemetente'] as String?,
        reactions: ((j['reactions'] as List?) ?? const [])
            .map((e) => ChatReaction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ChatInboxItem {
  final int alunoId;
  final String alunoNome;
  final String? fotoUrl;
  final String ultimaMensagem;
  final String ultimoRemetente;
  final DateTime enviadoEm;
  final int naoLidas;

  ChatInboxItem({
    required this.alunoId,
    required this.alunoNome,
    this.fotoUrl,
    required this.ultimaMensagem,
    required this.ultimoRemetente,
    required this.enviadoEm,
    required this.naoLidas,
  });

  factory ChatInboxItem.fromJson(Map<String, dynamic> j) => ChatInboxItem(
        alunoId: j['alunoId'] as int,
        alunoNome: j['alunoNome'] as String,
        fotoUrl: j['fotoUrl'] as String?,
        ultimaMensagem: j['ultimaMensagem'] as String? ?? '',
        ultimoRemetente: j['ultimoRemetente'] as String? ?? '',
        enviadoEm: DateTime.parse(j['enviadoEm'] as String),
        naoLidas: j['naoLidas'] as int? ?? 0,
      );
}

class ChatRepository {
  final Dio _dio;

  ChatRepository(ApiClient c) : _dio = c.dio;

  Future<List<ChatMsg>> historico(int alunoId) async {
    final r = await _dio.get('/api/chat/historico/$alunoId');
    return (r.data as List).map((e) => ChatMsg.fromJson(e)).toList();
  }

  Future<List<ChatInboxItem>> inbox() async {
    final r = await _dio.get('/api/chat/inbox');
    return (r.data as List)
        .map((e) => ChatInboxItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMsg> enviar(
    int alunoId,
    String conteudo,
    String remetente, {
    int? replyToMessageId,
  }) async {
    final r = await _dio.post('/api/chat/enviar', data: {
      'alunoId': alunoId,
      'conteudo': conteudo,
      'remetente': remetente,
      'clientMessageId': _clientMessageId(),
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    });
    return ChatMsg.fromJson(r.data);
  }

  Future<List<ChatMsg>> historicoAluno() async {
    final r = await _dio.get('/api/chat/aluno/historico');
    return (r.data as List).map((e) => ChatMsg.fromJson(e)).toList();
  }

  Future<List<ChatMsg>> buscarHistorico(int alunoId, String query) async {
    final r = await _dio.get(
      '/api/chat/historico/$alunoId/buscar',
      queryParameters: {'q': query},
    );
    return (r.data as List).map((e) => ChatMsg.fromJson(e)).toList();
  }

  Future<List<ChatMsg>> buscarHistoricoAluno(String query) async {
    final r = await _dio.get(
      '/api/chat/aluno/historico/buscar',
      queryParameters: {'q': query},
    );
    return (r.data as List).map((e) => ChatMsg.fromJson(e)).toList();
  }

  Future<void> marcarLido(int alunoId) async {
    await _dio.post('/api/chat/historico/$alunoId/marcar-lido');
  }

  Future<void> marcarLidoAluno() async {
    await _dio.post('/api/chat/aluno/marcar-lido');
  }

  Future<ChatMsg> enviarComoAluno(
    String conteudo, {
    int? replyToMessageId,
  }) async {
    final r = await _dio.post('/api/chat/aluno/enviar', data: {
      'conteudo': conteudo,
      'clientMessageId': _clientMessageId(),
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    });
    return ChatMsg.fromJson(r.data);
  }

  Future<ChatMsg> enviarMidiaComoAluno({
    required String conteudo,
    required String tipoMidia,
    required String midiaUrl,
    int? replyToMessageId,
  }) async {
    final r = await _dio.post('/api/chat/aluno/enviar', data: {
      'conteudo': conteudo,
      'tipoMidia': tipoMidia,
      'midiaUrl': midiaUrl,
      'clientMessageId': _clientMessageId(),
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    });
    return ChatMsg.fromJson(r.data);
  }

  Future<ChatMsg> enviarMidia({
    required int alunoId,
    required String conteudo,
    required String remetente,
    required String tipoMidia,
    required String midiaUrl,
    int? replyToMessageId,
  }) async {
    final r = await _dio.post('/api/chat/enviar', data: {
      'alunoId': alunoId,
      'conteudo': conteudo,
      'remetente': remetente,
      'tipoMidia': tipoMidia,
      'midiaUrl': midiaUrl,
      'clientMessageId': _clientMessageId(),
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    });
    return ChatMsg.fromJson(r.data);
  }

  Future<ChatMsg> toggleReaction(int messageId, String emoji) async {
    final r = await _dio.post(
      '/api/chat/messages/$messageId/reacao',
      data: {'emoji': emoji},
    );
    return ChatMsg.fromJson(r.data);
  }

  Future<ChatMsg> toggleReactionAluno(int messageId, String emoji) async {
    final r = await _dio.post(
      '/api/chat/aluno/messages/$messageId/reacao',
      data: {'emoji': emoji},
    );
    return ChatMsg.fromJson(r.data);
  }

  String _clientMessageId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'app-$now-${identityHashCode(this)}';
  }
}
