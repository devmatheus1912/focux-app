import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';

class DepoimentoModel {
  final int id;
  final String nomeAluno;
  final String? fotoAluno;
  final String texto;
  final int nota;
  final bool aprovado;

  DepoimentoModel({
    required this.id,
    required this.nomeAluno,
    this.fotoAluno,
    required this.texto,
    required this.nota,
    required this.aprovado,
  });

  factory DepoimentoModel.fromJson(Map<String, dynamic> j) => DepoimentoModel(
    id: j['id'] as int,
    nomeAluno: j['nomeAluno'] as String? ?? '',
    fotoAluno: j['fotoAluno'] as String?,
    texto: j['texto'] as String? ?? '',
    nota: j['nota'] as int? ?? 5,
    aprovado: j['aprovado'] as bool? ?? false,
  );
}

class DepoimentoRepository {
  final Dio _dio;
  DepoimentoRepository(ApiClient client) : _dio = client.dio;

  Future<DepoimentoModel> submeter({
    required String texto,
    required int nota,
  }) async {
    final r = await _dio.post(
      '/api/depoimentos',
      data: {'texto': texto, 'nota': nota},
    );
    return DepoimentoModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<DepoimentoModel>> listarMeus() async {
    final r = await _dio.get('/api/depoimentos');
    return (r.data as List)
        .map((e) => DepoimentoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Pagina<DepoimentoModel>> listarParaPersonalPagina({
    int page = 0,
    String q = '',
    bool? aprovado,
  }) async {
    final query = q.trim();
    final r = await _dio.get(
      '/api/personal/depoimentos',
      queryParameters: {
        'page': page,
        'size': 20,
        if (query.isNotEmpty) 'q': query,
        if (aprovado != null) 'aprovado': aprovado,
      },
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/personal/depoimentos devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => DepoimentoModel.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<void> aprovar(int id, {required bool aprovado}) async {
    await _dio.put(
      '/api/personal/depoimentos/$id/aprovar',
      queryParameters: {'aprovado': aprovado},
    );
  }
}
