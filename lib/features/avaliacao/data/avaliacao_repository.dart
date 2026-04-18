import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class AvaliacaoFisica {
  final int id;
  final double? pesoKg, alturaCm, percGordura, percMassa, cinturaCm, quadrilCm;
  final String? observacoes, avaliadoEm;
  final double? imc;
  final double? percentualGordura;
  final double? massaMuscular;
  final double? circCintura;
  final double? circQuadril;
  final double? circBraco;
  final double? circCoxa;
  final String? observacoesAvaliacao;
  final bool enviadaAoAluno;

  AvaliacaoFisica({
    required this.id,
    this.pesoKg,
    this.alturaCm,
    this.percGordura,
    this.percMassa,
    this.cinturaCm,
    this.quadrilCm,
    this.observacoes,
    this.avaliadoEm,
    this.imc,
    this.percentualGordura,
    this.massaMuscular,
    this.circCintura,
    this.circQuadril,
    this.circBraco,
    this.circCoxa,
    this.observacoesAvaliacao,
    this.enviadaAoAluno = false,
  });

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
    imc: (j['imc'] as num?)?.toDouble(),
    percentualGordura: (j['percentualGordura'] as num?)?.toDouble(),
    massaMuscular: (j['massaMuscular'] as num?)?.toDouble(),
    circCintura: (j['circCintura'] as num?)?.toDouble(),
    circQuadril: (j['circQuadril'] as num?)?.toDouble(),
    circBraco: (j['circBraco'] as num?)?.toDouble(),
    circCoxa: (j['circCoxa'] as num?)?.toDouble(),
    observacoesAvaliacao: j['observacoesAvaliacao'] as String?,
    enviadaAoAluno: j['enviadaAoAluno'] as bool? ?? false,
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
