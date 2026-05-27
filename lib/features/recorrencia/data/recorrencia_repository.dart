import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class RecorrenciaAssinatura {
  final int id;
  final int alunoId;
  final String? alunoNome;
  final double valor;
  final String status;
  final String? initPoint;
  final String? proximaCobranca;

  RecorrenciaAssinatura({
    required this.id,
    required this.alunoId,
    required this.valor,
    required this.status,
    this.alunoNome,
    this.initPoint,
    this.proximaCobranca,
  });

  factory RecorrenciaAssinatura.fromJson(Map<String, dynamic> j) =>
      RecorrenciaAssinatura(
        id: (j['id'] as num).toInt(),
        alunoId: (j['alunoId'] as num).toInt(),
        alunoNome: j['alunoNome'] as String?,
        valor: (j['valor'] as num?)?.toDouble() ?? 0,
        status: j['status'] as String? ?? 'PENDENTE',
        initPoint: j['initPoint'] as String?,
        proximaCobranca: j['proximaCobranca'] as String?,
      );
}

class RecorrenciaRepository {
  final Dio _dio;
  RecorrenciaRepository(ApiClient c) : _dio = c.dio;

  Future<List<RecorrenciaAssinatura>> listar() async {
    final r = await _dio.get('/api/recorrencia');
    return (r.data as List)
        .map((e) => RecorrenciaAssinatura.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecorrenciaAssinatura> criar({
    required int alunoId,
    required double valor,
  }) async {
    final r = await _dio.post('/api/recorrencia', data: {
      'alunoId': alunoId,
      'valor': valor,
    });
    return RecorrenciaAssinatura.fromJson(r.data as Map<String, dynamic>);
  }

  Future<RecorrenciaAssinatura?> minha() async {
    final r = await _dio.get('/api/recorrencia/minha');
    if (r.data == null) return null;
    return RecorrenciaAssinatura.fromJson(r.data as Map<String, dynamic>);
  }
}
