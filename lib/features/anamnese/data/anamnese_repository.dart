import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Anamnese {
  final int? id;
  final String? objetivo, nivelAtividade, lesoes, medicamentos, observacoes;

  Anamnese({this.id, this.objetivo, this.nivelAtividade, this.lesoes, this.medicamentos, this.observacoes});

  factory Anamnese.fromJson(Map<String, dynamic> j) => Anamnese(
    id: j['id'] as int?,
    objetivo: j['objetivo'] as String?,
    nivelAtividade: j['nivelAtividade'] as String?,
    lesoes: j['lesoes'] as String?,
    medicamentos: j['medicamentos'] as String?,
    observacoes: j['observacoes'] as String?,
  );
}

class AnamneseRepository {
  final Dio _dio;
  AnamneseRepository(ApiClient c) : _dio = c.dio;

  Future<Anamnese> buscar(int alunoId) async =>
      Anamnese.fromJson((await _dio.get('/api/alunos/$alunoId/anamnese')).data);

  Future<Anamnese> salvar(int alunoId, Map<String, dynamic> data) async =>
      Anamnese.fromJson((await _dio.put('/api/alunos/$alunoId/anamnese', data: data)).data);
}
