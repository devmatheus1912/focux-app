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
  final String? criadoEm;

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
    this.criadoEm,
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
    criadoEm: j['criadoEm'] as String?,
  );
}

class SnapshotAvaliacao {
  final double? pesoKg;
  final double? imc;
  final double? percGordura;
  final double? massaMuscular;
  final double? circCintura;
  final double? circQuadril;
  final double? circBraco;
  final double? circCoxa;
  final String? avaliadoEm;

  SnapshotAvaliacao({
    this.pesoKg,
    this.imc,
    this.percGordura,
    this.massaMuscular,
    this.circCintura,
    this.circQuadril,
    this.circBraco,
    this.circCoxa,
    this.avaliadoEm,
  });

  factory SnapshotAvaliacao.fromJson(Map<String, dynamic> j) =>
      SnapshotAvaliacao(
        pesoKg: (j['pesoKg'] as num?)?.toDouble(),
        imc: (j['imc'] as num?)?.toDouble(),
        percGordura:
            (j['percGordura'] ?? j['percentualGordura'] as num?)?.toDouble(),
        massaMuscular: (j['massaMuscular'] as num?)?.toDouble(),
        circCintura: (j['circCintura'] ?? j['cinturaCm'] as num?)?.toDouble(),
        circQuadril: (j['circQuadril'] ?? j['quadrilCm'] as num?)?.toDouble(),
        circBraco: (j['circBraco'] as num?)?.toDouble(),
        circCoxa: (j['circCoxa'] as num?)?.toDouble(),
        avaliadoEm: j['avaliadoEm'] as String?,
      );
}

class ComparativoEvolucao {
  final SnapshotAvaliacao primeira;
  final SnapshotAvaliacao atual;

  ComparativoEvolucao({required this.primeira, required this.atual});

  factory ComparativoEvolucao.fromJson(Map<String, dynamic> j) =>
      ComparativoEvolucao(
        primeira: SnapshotAvaliacao.fromJson(
          j['primeira'] as Map<String, dynamic>,
        ),
        atual: SnapshotAvaliacao.fromJson(j['atual'] as Map<String, dynamic>),
      );
}

class AvaliacaoRepository {
  final Dio _dio;
  AvaliacaoRepository(ApiClient c) : _dio = c.dio;

  Future<List<AvaliacaoFisica>> listar(int alunoId) async {
    final r = await _dio.get('/api/alunos/$alunoId/avaliacoes');
    return (r.data as List).map((e) => AvaliacaoFisica.fromJson(e)).toList();
  }

  Future<AvaliacaoFisica> registrar(
    int alunoId,
    Map<String, dynamic> data,
  ) async => AvaliacaoFisica.fromJson(
    (await _dio.post('/api/alunos/$alunoId/avaliacoes', data: data)).data,
  );

  Future<AvaliacaoFisica> editar(
    int alunoId,
    int avId,
    Map<String, dynamic> dados,
  ) async => AvaliacaoFisica.fromJson(
    (await _dio.put('/api/alunos/$alunoId/avaliacoes/$avId', data: dados)).data,
  );

  Future<void> excluir(int alunoId, int avId) async =>
      _dio.delete('/api/alunos/$alunoId/avaliacoes/$avId');

  Future<ComparativoEvolucao> comparativo(int alunoId) async {
    final response = await _dio.get(
      '/api/alunos/$alunoId/avaliacoes/comparativo',
    );
    return ComparativoEvolucao.fromJson(response.data);
  }
}
