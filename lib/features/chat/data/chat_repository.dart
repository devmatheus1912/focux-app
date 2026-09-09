import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';

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

class ChatAttachment {
  final String type;
  final String url;
  final String? fileName;
  final String? mimeType;
  final String? thumbnailUrl;
  final int? sizeBytes;
  final int? durationSeconds;

  const ChatAttachment({
    required this.type,
    required this.url,
    this.fileName,
    this.mimeType,
    this.thumbnailUrl,
    this.sizeBytes,
    this.durationSeconds,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> j) => ChatAttachment(
    type: j['type'] as String? ?? 'FILE',
    url: j['url'] as String? ?? '',
    fileName: j['fileName'] as String?,
    mimeType: j['mimeType'] as String?,
    thumbnailUrl: j['thumbnailUrl'] as String?,
    sizeBytes: j['sizeBytes'] as int?,
    durationSeconds: j['durationSeconds'] as int?,
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
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final List<ChatAttachment> attachments;
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
    this.editedAt,
    this.deletedAt,
    this.attachments = const [],
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
    deliveredAt:
        j['deliveredAt'] != null
            ? DateTime.tryParse(j['deliveredAt'].toString())
            : null,
    readAt:
        j['readAt'] != null ? DateTime.tryParse(j['readAt'].toString()) : null,
    replyToMessageId: j['replyToMessageId'] as int?,
    replyToConteudo: j['replyToConteudo'] as String?,
    replyToRemetente: j['replyToRemetente'] as String?,
    editedAt:
        j['editedAt'] != null
            ? DateTime.tryParse(j['editedAt'].toString())
            : null,
    deletedAt:
        j['deletedAt'] != null
            ? DateTime.tryParse(j['deletedAt'].toString())
            : null,
    attachments:
        ((j['attachments'] as List?) ?? const [])
            .map((e) => ChatAttachment.fromJson(e as Map<String, dynamic>))
            .where((e) => e.url.isNotEmpty)
            .toList(),
    reactions:
        ((j['reactions'] as List?) ?? const [])
            .map((e) => ChatReaction.fromJson(e as Map<String, dynamic>))
            .toList(),
  );

  ChatAttachment? get primaryAttachment {
    if (attachments.isNotEmpty) return attachments.first;
    if (midiaUrl == null || midiaUrl!.isEmpty) return null;
    return ChatAttachment(type: tipoMidia ?? 'FILE', url: midiaUrl!);
  }

  String? get primaryMediaType {
    final type = primaryAttachment?.type ?? tipoMidia;
    return type == 'IMAGEM' ? 'IMAGE' : type;
  }

  String? get primaryMediaUrl => primaryAttachment?.url ?? midiaUrl;
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

class ChatPage {
  final List<ChatMsg> items;
  final int? nextBeforeId;
  final bool hasMore;

  const ChatPage({
    required this.items,
    required this.nextBeforeId,
    required this.hasMore,
  });

  factory ChatPage.fromJson(Map<String, dynamic> j) => ChatPage(
    items:
        ((j['items'] as List?) ?? const [])
            .map((e) => ChatMsg.fromJson(e as Map<String, dynamic>))
            .toList(),
    nextBeforeId: j['nextBeforeId'] as int?,
    hasMore: j['hasMore'] as bool? ?? false,
  );
}

class ChatRepository {
  final Dio _dio;

  ChatRepository(ApiClient c) : _dio = c.dio;

  Future<ChatPage> historicoPage(
    int alunoId, {
    int? beforeId,
    int limit = 30,
  }) async {
    final r = await _dio.get(
      '/api/chat/historico/$alunoId/page',
      queryParameters: {
        'limit': limit,
        if (beforeId != null) 'beforeId': beforeId,
      },
    );
    return ChatPage.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<ChatInboxItem>> inbox() async {
    return (await inboxPage()).items;
  }

  Future<ChatInboxPage> inboxPage({int page = 0, int size = 50}) async {
    final r = await _dio.get(
      '/api/chat/inbox',
      queryParameters: {'page': page, 'size': size},
    );
    return ChatInboxPage.fromJson(r.data as Map<String, dynamic>);
  }

  /// BFF tipado — first paint da inbox (inbox + unread + archived).
  Future<ChatInboxHomeBundle> inboxHome() async {
    final r = await _dio.get('/api/chat/inbox/home');
    return ChatInboxHomeBundle.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ChatMsg> enviar(
    int alunoId,
    String conteudo,
    String remetente, {
    int? replyToMessageId,
  }) async {
    final r = await _dio.post(
      '/api/chat/enviar',
      data: {
        'alunoId': alunoId,
        'conteudo': conteudo,
        'remetente': remetente,
        'clientMessageId': _clientMessageId(),
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      },
    );
    return ChatMsg.fromJson(r.data);
  }

  Future<ChatPage> historicoAlunoPage({int? beforeId, int limit = 30}) async {
    final r = await _dio.get(
      '/api/chat/aluno/historico/page',
      queryParameters: {
        'limit': limit,
        if (beforeId != null) 'beforeId': beforeId,
      },
    );
    return ChatPage.fromJson(r.data as Map<String, dynamic>);
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
    final r = await _dio.post(
      '/api/chat/aluno/enviar',
      data: {
        'conteudo': conteudo,
        'clientMessageId': _clientMessageId(),
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      },
    );
    return ChatMsg.fromJson(r.data);
  }

  Future<ChatMsg> enviarMidiaComoAluno({
    required String conteudo,
    required String tipoMidia,
    required String midiaUrl,
    int? replyToMessageId,
  }) async {
    final r = await _dio.post(
      '/api/chat/aluno/enviar',
      data: {
        'conteudo': conteudo,
        'tipoMidia': tipoMidia,
        'midiaUrl': midiaUrl,
        'clientMessageId': _clientMessageId(),
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      },
    );
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
    final r = await _dio.post(
      '/api/chat/enviar',
      data: {
        'alunoId': alunoId,
        'conteudo': conteudo,
        'remetente': remetente,
        'tipoMidia': tipoMidia,
        'midiaUrl': midiaUrl,
        'clientMessageId': _clientMessageId(),
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      },
    );
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

  Future<ChatMsg> editarMensagem(int messageId, String conteudo) async {
    final r = await _dio.patch(
      '/api/chat/messages/$messageId',
      data: {'conteudo': conteudo},
    );
    return ChatMsg.fromJson(r.data);
  }

  Future<ChatMsg> editarMensagemAluno(int messageId, String conteudo) async {
    final r = await _dio.patch(
      '/api/chat/aluno/messages/$messageId',
      data: {'conteudo': conteudo},
    );
    return ChatMsg.fromJson(r.data);
  }

  Future<ChatMsg> apagarMensagem(int messageId) async {
    final r = await _dio.delete('/api/chat/messages/$messageId');
    return ChatMsg.fromJson(r.data);
  }

  Future<ChatMsg> apagarMensagemAluno(int messageId) async {
    final r = await _dio.delete('/api/chat/aluno/messages/$messageId');
    return ChatMsg.fromJson(r.data);
  }

  // ── Fase 2: WhatsApp-level conversation management ─────────────────────────

  /// Pin, unpin, archive, unarchive, mute, unmute, or clear a conversation
  Future<Map<String, dynamic>> conversationAction(
    int alunoId,
    String action,
  ) async {
    final r = await _dio.post(
      '/api/chat/conversas/$alunoId/action',
      data: {'action': action},
    );
    return r.data as Map<String, dynamic>;
  }

  /// Get conversation state (pinned/archived/muted)
  Future<Map<String, dynamic>> conversationState(int alunoId) async {
    final r = await _dio.get('/api/chat/conversas/$alunoId/state');
    return r.data as Map<String, dynamic>;
  }

  Future<Pagina<ChatInboxItem>> inboxArchivedPage({
    int page = 0,
    int size = 50,
  }) async {
    final r = await _dio.get(
      '/api/chat/inbox/archived',
      queryParameters: {'page': page, 'size': size},
    );
    return _pagina(
      r.data,
      'GET /api/chat/inbox/archived',
      ChatInboxItem.fromJson,
    );
  }

  /// Global search across all conversations
  Future<List<ChatMsg>> globalSearch(String query) async {
    return (await globalSearchPage(query)).content;
  }

  Future<Pagina<ChatMsg>> globalSearchPage(
    String query, {
    int page = 0,
  }) async {
    final r = await _dio.get(
      '/api/chat/inbox/search',
      queryParameters: {'q': query.trim(), 'page': page},
    );
    if (r.data is! Map) {
      throw const FormatException(
        'GET /api/chat/inbox/search devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(r.data as Map),
      (item) => ChatMsg.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<Pagina<ChatInboxItem>> inboxUnreadPage({
    int page = 0,
    int size = 50,
  }) async {
    final r = await _dio.get(
      '/api/chat/inbox/unread',
      queryParameters: {'page': page, 'size': size},
    );
    return _pagina(
      r.data,
      'GET /api/chat/inbox/unread',
      ChatInboxItem.fromJson,
    );
  }

  Pagina<T> _pagina<T>(
    dynamic data,
    String endpoint,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (data is! Map) {
      throw FormatException('$endpoint devolve Pagina, não lista crua.');
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => parse(Map<String, dynamic>.from(item as Map)),
    );
  }

  String _clientMessageId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'app-$now-${identityHashCode(this)}';
  }
}

class ChatInboxHomeBundle {
  final List<ChatInboxItem> inbox;
  final List<ChatInboxItem> unread;
  final List<ChatInboxItem> archived;
  final bool inboxHasMore;
  final int inboxTotal;
  final int inboxPage;
  final int inboxSize;
  final bool unreadHasMore;
  final int unreadTotal;
  final bool archivedHasMore;
  final int archivedTotal;

  ChatInboxHomeBundle({
    required this.inbox,
    required this.unread,
    required this.archived,
    this.inboxHasMore = false,
    this.inboxTotal = 0,
    this.inboxPage = 0,
    this.inboxSize = 50,
    this.unreadHasMore = false,
    this.unreadTotal = 0,
    this.archivedHasMore = false,
    this.archivedTotal = 0,
  });

  factory ChatInboxHomeBundle.fromJson(Map<String, dynamic> j) {
    List<ChatInboxItem> parse(String key) =>
        ((j[key] as List?) ?? const [])
            .map((e) => ChatInboxItem.fromJson(e as Map<String, dynamic>))
            .toList();
    final inbox = parse('inbox');
    final unread = parse('unread');
    final archived = parse('archived');
    return ChatInboxHomeBundle(
      inbox: inbox,
      unread: unread,
      archived: archived,
      inboxHasMore: j['inboxHasMore'] as bool? ?? false,
      inboxTotal: (j['inboxTotal'] as num?)?.toInt() ?? inbox.length,
      inboxPage: (j['inboxPage'] as num?)?.toInt() ?? 0,
      inboxSize: (j['inboxSize'] as num?)?.toInt() ?? 50,
      unreadHasMore: j['unreadHasMore'] as bool? ?? false,
      unreadTotal: (j['unreadTotal'] as num?)?.toInt() ?? unread.length,
      archivedHasMore: j['archivedHasMore'] as bool? ?? false,
      archivedTotal: (j['archivedTotal'] as num?)?.toInt() ?? archived.length,
    );
  }
}

class ChatInboxPage {
  const ChatInboxPage({
    required this.items,
    required this.hasMore,
    required this.page,
    required this.total,
    required this.size,
  });

  final List<ChatInboxItem> items;
  final bool hasMore;
  final int page;
  final int total;
  final int size;

  factory ChatInboxPage.fromJson(Map<String, dynamic> j) {
    final raw = (j['items'] as List?) ?? const [];
    return ChatInboxPage(
      items:
          raw
              .map((e) => ChatInboxItem.fromJson(e as Map<String, dynamic>))
              .toList(),
      hasMore: j['hasMore'] as bool? ?? false,
      page: (j['page'] as num?)?.toInt() ?? 0,
      total: (j['total'] as num?)?.toInt() ?? raw.length,
      size: (j['size'] as num?)?.toInt() ?? raw.length,
    );
  }
}
