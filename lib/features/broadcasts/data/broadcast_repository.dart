import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

/// Modelo de um broadcast enviado.
class Broadcast {
  final int id;
  final String titulo;
  final String mensagem;
  final String? tipoConsultoriaAlvo;
  final DateTime enviadoEm;
  final int totalEnviados;

  Broadcast({
    required this.id,
    required this.titulo,
    required this.mensagem,
    this.tipoConsultoriaAlvo,
    required this.enviadoEm,
    required this.totalEnviados,
  });

  factory Broadcast.fromJson(Map<String, dynamic> json) => Broadcast(
    id: json['id'] as int,
    titulo: json['titulo'] as String,
    mensagem: json['mensagem'] as String,
    tipoConsultoriaAlvo: json['tipoConsultoriaAlvo'] as String?,
    enviadoEm: DateTime.parse(json['enviadoEm'] as String),
    totalEnviados: json['totalEnviados'] as int,
  );
}

/// Repositório de broadcasts — envia notificações push em massa e lista histórico.
class BroadcastRepository {
  final Dio _dio;

  BroadcastRepository(ApiClient client) : _dio = client.dio;

  /// Envia um broadcast para os alunos do personal.
  /// [tipoConsultoriaAlvo]: ONLINE, PRESENCIAL, HIBRIDO — null envia para todos.
  Future<Broadcast> enviar({
    required String titulo,
    required String mensagem,
    String? tipoConsultoriaAlvo,
  }) async {
    final response = await _dio.post(
      '/api/broadcasts',
      data: {
        'titulo': titulo,
        'mensagem': mensagem,
        if (tipoConsultoriaAlvo != null && tipoConsultoriaAlvo != 'TODOS')
          'tipoConsultoriaAlvo': tipoConsultoriaAlvo,
      },
    );
    return Broadcast.fromJson(response.data as Map<String, dynamic>);
  }

  /// Lista o histórico de broadcasts enviados pelo personal autenticado.
  Future<List<Broadcast>> listar() async {
    final response = await _dio.get('/api/broadcasts');
    final lista = response.data as List<dynamic>;
    return lista
        .map((e) => Broadcast.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
