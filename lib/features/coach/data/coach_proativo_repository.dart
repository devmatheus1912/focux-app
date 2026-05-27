import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class CoachMensagem {
  final int id;
  final String tipo;
  final String mensagem;
  final String criadoEm;
  final bool lido;

  CoachMensagem({
    required this.id,
    required this.tipo,
    required this.mensagem,
    required this.criadoEm,
    required this.lido,
  });

  factory CoachMensagem.fromJson(Map<String, dynamic> j) => CoachMensagem(
    id: (j['id'] as num).toInt(),
    tipo: j['tipo'] as String? ?? '',
    mensagem: j['mensagem'] as String? ?? '',
    criadoEm: j['criadoEm'] as String? ?? '',
    lido: j['lido'] as bool? ?? false,
  );
}

class CoachProativoRepository {
  final Dio _dio;
  CoachProativoRepository(ApiClient c) : _dio = c.dio;

  Future<List<CoachMensagem>> mensagens() async {
    final r = await _dio.get('/api/coach-proativo/mensagens');
    return (r.data as List)
        .map((e) => CoachMensagem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> marcarLido(int id) async {
    await _dio.post('/api/coach-proativo/mensagens/$id/lido');
  }
}
