import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';
import '../../../core/money/fx_money.dart';

class RecorrenciaAssinatura {
  final int id;
  final int alunoId;
  final String? alunoNome;
  final FxMoney valor;
  final String status;
  final String? initPoint;
  final String? proximaCobranca;

  RecorrenciaAssinatura({
    required this.id,
    required this.alunoId,
    required Object valor,
    required this.status,
    this.alunoNome,
    this.initPoint,
    this.proximaCobranca,
  }) : valor = FxMoney.parse(valor);

  factory RecorrenciaAssinatura.fromJson(Map<String, dynamic> j) =>
      RecorrenciaAssinatura(
        id: (j['id'] as num).toInt(),
        alunoId: (j['alunoId'] as num).toInt(),
        alunoNome: j['alunoNome'] as String?,
        valor: j['valor'] ?? 0,
        status: j['status'] as String? ?? 'PENDENTE',
        initPoint: j['initPoint'] as String?,
        proximaCobranca: j['proximaCobranca'] as String?,
      );
}

class RecorrenciaRepository {
  final Dio _dio;
  RecorrenciaRepository(ApiClient c) : _dio = c.dio;

  Future<Pagina<RecorrenciaAssinatura>> listarPagina({
    int page = 0,
    int size = 20,
    String? q,
    String? status,
  }) async {
    final query = q?.trim() ?? '';
    final r = await _dio.get(
      '/api/recorrencia',
      queryParameters: {
        'page': page,
        'size': size,
        if (query.isNotEmpty) 'q': query,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final data = r.data;
    if (data is! Map) {
      throw const FormatException(
        'GET /api/recorrencia devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => RecorrenciaAssinatura.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    );
  }

  Future<RecorrenciaAssinatura> criar({
    required int alunoId,
    required FxMoney valor,
  }) async {
    final r = await _dio.post(
      '/api/recorrencia',
      data: {'alunoId': alunoId, 'valor': valor.wire},
    );
    return RecorrenciaAssinatura.fromJson(r.data as Map<String, dynamic>);
  }

  Future<RecorrenciaAssinatura?> minha() async {
    final r = await _dio.get('/api/recorrencia/minha');
    if (r.data == null) return null;
    return RecorrenciaAssinatura.fromJson(r.data as Map<String, dynamic>);
  }

  Future<RecorrenciaAssinatura> pausarMinha() async {
    final r = await _dio.post('/api/recorrencia/minha/pausar');
    return RecorrenciaAssinatura.fromJson(r.data as Map<String, dynamic>);
  }

  Future<RecorrenciaAssinatura> retomarMinha() async {
    final r = await _dio.post('/api/recorrencia/minha/retomar');
    return RecorrenciaAssinatura.fromJson(r.data as Map<String, dynamic>);
  }
}
