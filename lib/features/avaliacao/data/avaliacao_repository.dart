import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class AvaliacaoFisica {
  final int id;
  final double? pesoKg, alturaCm, percGordura, percMassa, cinturaCm, quadrilCm;
  final String? observacoes, avaliadoEm;

  AvaliacaoFisica({required this.id, this.pesoKg, this.alturaCm, this.percGordura,
      this.percMassa, this.cinturaCm, this.quadrilCm, this.observacoes, this.avaliadoEm});

  factory AvaliacaoFisica.fromJson(Map<String, dynamic> j) => AvaliacaoFisica(
    id: j['id'] as int,
    pesoKg: (j['pesoKg'] as num?)?.toDouble(),
    alturaCm: (j['alturaCm'] as num?)?.toDouble(),
    percGordura: (j['percGordura'] as num?)?.toDouble(),
    percMassa: (j['percMassa'] as num?)?.toDouble(),
    cinturaCm: (j['cinturaCm'] as num?)?.toDouble(),
    quadrilCm: (j['quadrilCm'] as num?)?.toDouble(),
    observacoes: j['observacoes'] as String?,
    avaliadoEm: j['avaliadoEm'] as String?,
  );
}

class AvaliacaoRepository {
  final Dio _dio;
  AvaliacaoRepository(ApiClient c) : _dio = c.dio;

  Future<List<AvaliacaoFisica>> listar(int alunoId) async {
    final r = await _dio.get('/api/alunos/$alunoId/avaliacoes');
    return (r.data as List).map((e) => AvaliacaoFisica.fromJson(e)).toList();
  }

  Future<AvaliacaoFisica> registrar(int alunoId, Map<String, dynamic> data) async =>
      AvaliacaoFisica.fromJson((await _dio.post('/api/alunos/$alunoId/avaliacoes', data: data)).data);
}
