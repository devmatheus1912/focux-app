import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class SuporteTicket {
  final int id;
  final int? personalId;
  final String? nomePessoal;
  final String titulo;
  final String descricao;
  final String severidade;
  final String status;
  final String? classeAfetada;
  final String? sugestaoIa;
  final String? respostaAdmin;
  final String? criadoEm;
  final String? resolvidoEm;

  SuporteTicket({required this.id, this.personalId, this.nomePessoal,
    required this.titulo, required this.descricao, required this.severidade,
    required this.status, this.classeAfetada, this.sugestaoIa,
    this.respostaAdmin, this.criadoEm, this.resolvidoEm});

  factory SuporteTicket.fromJson(Map<String, dynamic> j) => SuporteTicket(
    id: j['id'] as int,
    personalId: j['personalId'] as int?,
    nomePessoal: j['nomePessoal'] as String?,
    titulo: j['titulo'] as String,
    descricao: j['descricao'] as String,
    severidade: j['severidade'] as String,
    status: j['status'] as String,
    classeAfetada: j['classeAfetada'] as String?,
    sugestaoIa: j['sugestaoIa'] as String?,
    respostaAdmin: j['respostaAdmin'] as String?,
    criadoEm: j['criadoEm'] as String?,
    resolvidoEm: j['resolvidoEm'] as String?,
  );
}

class SuporteRepository {
  final Dio _dio;
  SuporteRepository(ApiClient c) : _dio = c.dio;

  Future<SuporteTicket> criarTicket({
    required String titulo,
    required String descricao,
    required String severidade,
    String? classeAfetada,
  }) async {
    final r = await _dio.post('/api/suporte/tickets', data: {
      'titulo': titulo,
      'descricao': descricao,
      'severidade': severidade,
      if (classeAfetada != null && classeAfetada.isNotEmpty) 'classeAfetada': classeAfetada,
    });
    return SuporteTicket.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<SuporteTicket>> meusTickets() async {
    final r = await _dio.get('/api/suporte/tickets/meus');
    return (r.data as List)
        .map((j) => SuporteTicket.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<String> chat(String mensagem, {int? ticketId}) async {
    final r = await _dio.post('/api/suporte/chat', data: {
      'mensagem': mensagem,
      if (ticketId != null) 'ticketId': ticketId,
    });
    return (r.data as Map<String, dynamic>)['resposta'] as String;
  }
}
