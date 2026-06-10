import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../plano_sucesso_model.dart';

class PlanoSucessoRepository {
  final Dio _dio;
  PlanoSucessoRepository(ApiClient client) : _dio = client.dio;

  Future<PlanoSucesso> buscarPorAluno(int alunoId) async {
    final r = await _dio.get('/api/planos-sucesso/aluno/$alunoId');
    return PlanoSucesso.fromJson(r.data as Map<String, dynamic>);
  }
}
