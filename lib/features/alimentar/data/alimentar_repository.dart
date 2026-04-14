import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class PlanoAlimentar {
  final int id;
  final String nome;
  final int? caloriasDia, proteinaG, carboidratoG, gorduraG;
  final String? observacoes, criadoEm;

  PlanoAlimentar({required this.id, required this.nome, this.caloriasDia,
      this.proteinaG, this.carboidratoG, this.gorduraG, this.observacoes, this.criadoEm});

  factory PlanoAlimentar.fromJson(Map<String, dynamic> j) => PlanoAlimentar(
    id: j['id'] as int, nome: j['nome'] as String,
    caloriasDia: j['caloriasDia'] as int?, proteinaG: j['proteinaG'] as int?,
    carboidratoG: j['carboidratoG'] as int?, gorduraG: j['gorduraG'] as int?,
    observacoes: j['observacoes'] as String?, criadoEm: j['criadoEm'] as String?,
  );
}

class AlimentarRepository {
  final Dio _dio;
  AlimentarRepository(ApiClient c) : _dio = c.dio;

  Future<List<PlanoAlimentar>> listar(int alunoId) async {
    final r = await _dio.get('/api/alunos/$alunoId/planos-alimentares');
    return (r.data as List).map((e) => PlanoAlimentar.fromJson(e)).toList();
  }

  Future<PlanoAlimentar> criar(int alunoId, Map<String, dynamic> data) async =>
      PlanoAlimentar.fromJson((await _dio.post('/api/alunos/$alunoId/planos-alimentares', data: data)).data);
}
