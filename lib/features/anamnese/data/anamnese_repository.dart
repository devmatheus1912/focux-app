import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Anamnese {
  final int? id;
  final String? objetivo;
  final String? nivelAtividade;
  final String? lesoes;
  final String? medicamentos;
  final String? observacoes;
  // Novos campos
  final String? historicoMedico;
  final String? cirurgias;
  final String? doresCronicas;
  final String? objetivoDetalhado;
  final int? disponibilidadeSemanal;
  final String? preferenciasTreino;
  final String? restricoesAlimentares;

  Anamnese({
    this.id,
    this.objetivo,
    this.nivelAtividade,
    this.lesoes,
    this.medicamentos,
    this.observacoes,
    this.historicoMedico,
    this.cirurgias,
    this.doresCronicas,
    this.objetivoDetalhado,
    this.disponibilidadeSemanal,
    this.preferenciasTreino,
    this.restricoesAlimentares,
  });

  factory Anamnese.fromJson(Map<String, dynamic> j) => Anamnese(
    id: j['id'] as int?,
    objetivo: j['objetivo'] as String?,
    nivelAtividade: j['nivelAtividade'] as String?,
    lesoes: j['lesoes'] as String?,
    medicamentos: j['medicamentos'] as String?,
    observacoes: j['observacoes'] as String?,
    historicoMedico: j['historicoMedico'] as String?,
    cirurgias: j['cirurgias'] as String?,
    doresCronicas: j['doresCronicas'] as String?,
    objetivoDetalhado: j['objetivoDetalhado'] as String?,
    disponibilidadeSemanal: j['disponibilidadeSemanal'] as int?,
    preferenciasTreino: j['preferenciasTreino'] as String?,
    restricoesAlimentares: j['restricoesAlimentares'] as String?,
  );
}

class AnamneseRepository {
  final Dio _dio;
  AnamneseRepository(ApiClient c) : _dio = c.dio;

  Future<Anamnese> buscar(int alunoId) async =>
      Anamnese.fromJson((await _dio.get('/api/alunos/$alunoId/anamnese')).data);

  Future<Anamnese> salvar(int alunoId, Map<String, dynamic> data) async =>
      Anamnese.fromJson(
        (await _dio.put('/api/alunos/$alunoId/anamnese', data: data)).data,
      );

  Future<Anamnese> buscarMinha() async =>
      Anamnese.fromJson((await _dio.get('/api/aluno/anamnese')).data);

  Future<Anamnese> salvarMinha(Map<String, dynamic> data) async =>
      Anamnese.fromJson(
        (await _dio.put('/api/aluno/anamnese', data: data)).data,
      );
}
