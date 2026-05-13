import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

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

  Future<List<DepoimentoModel>> listarParaPersonal() async {
    final r = await _dio.get('/api/personal/depoimentos');
    return (r.data as List)
        .map((e) => DepoimentoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> aprovar(int id, {required bool aprovado}) async {
    await _dio.put(
      '/api/personal/depoimentos/$id/aprovar',
      queryParameters: {'aprovado': aprovado},
    );
  }
}
