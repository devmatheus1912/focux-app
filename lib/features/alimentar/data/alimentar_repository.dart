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

class Refeicao {
  final int id;
  final int planoAlimentarId;
  final String nomeRefeicao;
  final String? horario;
  final int? calorias;
  final int? proteinaG;
  final int? carboG;
  final int? gorduraG;
  final String? alimentos;
  final String? criadoEm;

  Refeicao({
    required this.id,
    required this.planoAlimentarId,
    required this.nomeRefeicao,
    this.horario,
    this.calorias,
    this.proteinaG,
    this.carboG,
    this.gorduraG,
    this.alimentos,
    this.criadoEm,
  });

  factory Refeicao.fromJson(Map<String, dynamic> j) => Refeicao(
    id: j['id'] as int,
    planoAlimentarId: j['planoAlimentarId'] as int,
    nomeRefeicao: j['nomeRefeicao'] as String,
    horario: j['horario'] as String?,
    calorias: j['calorias'] as int?,
    proteinaG: j['proteinaG'] as int?,
    carboG: j['carboG'] as int?,
    gorduraG: j['gorduraG'] as int?,
    alimentos: j['alimentos'] as String?,
    criadoEm: j['criadoEm'] as String?,
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

  Future<List<Refeicao>> listarRefeicoes(int alunoId, int planoId) async {
    final r = await _dio.get('/api/alunos/$alunoId/planos-alimentares/$planoId/refeicoes');
    return (r.data as List).map((e) => Refeicao.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Refeicao> criarRefeicao(int alunoId, int planoId, Map<String, dynamic> data) async {
    final r = await _dio.post('/api/alunos/$alunoId/planos-alimentares/$planoId/refeicoes', data: data);
    return Refeicao.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> excluirRefeicao(int alunoId, int planoId, int refeicaoId) async {
    await _dio.delete('/api/alunos/$alunoId/planos-alimentares/$planoId/refeicoes/$refeicaoId');
  }
}
