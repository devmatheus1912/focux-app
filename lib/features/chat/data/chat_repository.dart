import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class ChatMsg {
  final int? id;
  final int? alunoId;
  final String remetente;
  final String conteudo;
  final DateTime enviadoEm;
  final String? tipoMidia;
  final String? midiaUrl;

  ChatMsg({
    this.id, 
    this.alunoId, 
    required this.remetente,
    required this.conteudo, 
    required this.enviadoEm,
    this.tipoMidia,
    this.midiaUrl,
  });

  factory ChatMsg.fromJson(Map<String, dynamic> j) => ChatMsg(
    id: j['id'] as int?,
    alunoId: j['alunoId'] as int?,
    remetente: j['remetente'] as String,
    conteudo: j['conteudo'] as String,
    enviadoEm: DateTime.parse(j['enviadoEm'] as String),
    tipoMidia: j['tipoMidia'] as String?,
    midiaUrl: j['midiaUrl'] as String?,
  );
}

class ChatRepository {
  final Dio _dio;
  ChatRepository(ApiClient c) : _dio = c.dio;

  Future<List<ChatMsg>> historico(int alunoId) async {
    final r = await _dio.get('/api/chat/historico/$alunoId');
    return (r.data as List).map((e) => ChatMsg.fromJson(e)).toList();
  }

  Future<ChatMsg> enviar(int alunoId, String conteudo, String remetente) async {
    final r = await _dio.post('/api/chat/enviar', data: {
      'alunoId': alunoId,
      'conteudo': conteudo,
      'remetente': remetente,
    });
    return ChatMsg.fromJson(r.data);
  }

  Future<List<ChatMsg>> historicoAluno() async {
    final r = await _dio.get('/api/chat/aluno/historico');
    return (r.data as List).map((e) => ChatMsg.fromJson(e)).toList();
  }

  Future<ChatMsg> enviarComoAluno(String conteudo) async {
    final r = await _dio.post('/api/chat/aluno/enviar', data: {'conteudo': conteudo});
    return ChatMsg.fromJson(r.data);
  }
}
