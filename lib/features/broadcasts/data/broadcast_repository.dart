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

  factory Broadcast.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final countRaw = json['totalEnviados'];
    return Broadcast(
      id: idRaw is num ? idRaw.toInt() : 0,
      titulo: '${json['titulo'] ?? ''}',
      mensagem: '${json['mensagem'] ?? ''}',
      tipoConsultoriaAlvo: json['tipoConsultoriaAlvo'] as String?,
      enviadoEm:
          DateTime.tryParse('${json['enviadoEm'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      totalEnviados: countRaw is num ? countRaw.toInt() : 0,
    );
  }
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
    final raw = response.data;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Broadcast.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
