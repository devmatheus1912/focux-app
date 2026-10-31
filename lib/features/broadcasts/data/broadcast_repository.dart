import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';

/// Modelo de um broadcast enviado.
class Broadcast {
  final int id;
  final String titulo;
  final String mensagem;
  final String? tipoConsultoriaAlvo;
  final DateTime enviadoEm;
  final int totalEnviados;

  /// Alunos com push ativo no envio; null em broadcasts antigos (não medido).
  final int? totalComPush;

  Broadcast({
    required this.id,
    required this.titulo,
    required this.mensagem,
    this.tipoConsultoriaAlvo,
    required this.enviadoEm,
    required this.totalEnviados,
    this.totalComPush,
  });

  factory Broadcast.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final countRaw = json['totalEnviados'];
    final pushRaw = json['totalComPush'];
    return Broadcast(
      id: idRaw is num ? idRaw.toInt() : 0,
      titulo: '${json['titulo'] ?? ''}',
      mensagem: '${json['mensagem'] ?? ''}',
      tipoConsultoriaAlvo: json['tipoConsultoriaAlvo'] as String?,
      enviadoEm:
          DateTime.tryParse('${json['enviadoEm'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      totalEnviados: countRaw is num ? countRaw.toInt() : 0,
      totalComPush: pushRaw is num ? pushRaw.toInt() : null,
    );
  }
}

/// Quantos alunos um público alcança agora, pela regra do envio.
typedef BroadcastAlcance = ({int total, int comPush});

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
    return Pagina<Broadcast>.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      (e) => Broadcast.fromJson(Map<String, dynamic>.from(e as Map)),
    ).content;
  }

  /// Por público: TODOS, ONLINE, PRESENCIAL e HIBRIDO.
  Future<Map<String, BroadcastAlcance>> alcance() async {
    final response = await _dio.get('/api/broadcasts/alcance');
    return {
      for (final item in (response.data as List).whereType<Map>())
        '${item['publico']}': (
          total: (item['total'] as num).toInt(),
          comPush: (item['comPush'] as num).toInt(),
        ),
    };
  }
}
