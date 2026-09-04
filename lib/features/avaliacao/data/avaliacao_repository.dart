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
  final double? alturaCm;
  final double? imc;
  final double? percGordura;
  final double? percMassa;
  final double? massaMuscular;
  final double? circCintura;
  final double? circQuadril;
  final double? circBraco;
  final double? circCoxa;
  final String? avaliadoEm;

  SnapshotAvaliacao({
    this.pesoKg,
    this.alturaCm,
    this.imc,
    this.percGordura,
    this.percMassa,
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
        alturaCm: (j['alturaCm'] as num?)?.toDouble(),
        imc: (j['imc'] as num?)?.toDouble(),
        percGordura:
            (j['percGordura'] ?? j['percentualGordura'] as num?)?.toDouble(),
        percMassa: (j['percMassa'] as num?)?.toDouble(),
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
  final double? diferencaPeso;

  ComparativoEvolucao({
    required this.primeira,
    required this.atual,
    this.diferencaPeso,
  });

  factory ComparativoEvolucao.fromJson(Map<String, dynamic> j) {
    final primeiraRaw = j['primeira'];
    final atualRaw = j['atual'] ?? j['ultima'];
    if (primeiraRaw is! Map || atualRaw is! Map) {
      throw const FormatException('Comparativo sem primeira e última avaliação');
    }
    return ComparativoEvolucao(
      primeira: SnapshotAvaliacao.fromJson(
        Map<String, dynamic>.from(primeiraRaw),
      ),
      atual: SnapshotAvaliacao.fromJson(Map<String, dynamic>.from(atualRaw)),
      diferencaPeso: (j['diferencaPeso'] as num?)?.toDouble(),
    );
  }
}

/// Aceita lista crua (legado) ou envelope `PaginaResponse` (`content` / `items`).
List<AvaliacaoFisica> avaliacoesFromResponse(dynamic data) {
  final raw = switch (data) {
    List list => list,
    Map map => map['content'] ?? map['items'] ?? map['itens'],
    _ => null,
  };
  if (raw is! List) return const [];
  return [
    for (final row in raw)
      if (row is Map)
        AvaliacaoFisica.fromJson(Map<String, dynamic>.from(row)),
  ];
}

class AvaliacoesPagina {
  const AvaliacoesPagina({required this.content, required this.hasNext});

  final List<AvaliacaoFisica> content;
  final bool hasNext;
}

AvaliacoesPagina avaliacoesPaginaFromResponse(dynamic data) {
  return AvaliacoesPagina(
    content: avaliacoesFromResponse(data),
    hasNext: data is Map && data['hasNext'] == true,
  );
}

/// Páginas newest-first → até [maxPontos] pesos, do mais antigo ao mais novo.
List<double> pesosHistoricoFromPaginas(
  Iterable<AvaliacoesPagina> paginas, {
  int maxPontos = 7,
}) {
  final newestFirst = <double>[];
  for (final pagina in paginas) {
    for (final row in pagina.content) {
      final peso = row.pesoKg;
      if (peso == null) continue;
      newestFirst.add(peso);
      if (newestFirst.length >= maxPontos) {
        return newestFirst.reversed.toList();
      }
    }
    if (!pagina.hasNext) break;
  }
  return newestFirst.reversed.toList();
}

class AvaliacaoRepository {
  final Dio _dio;
  AvaliacaoRepository(ApiClient c) : _dio = c.dio;

  Future<List<AvaliacaoFisica>> listar(int alunoId) async {
    final pagina = await listarPagina(alunoId, page: 0, size: 100);
    return pagina.content;
  }

  Future<AvaliacoesPagina> listarPagina(
    int alunoId, {
    int page = 0,
    int size = 100,
  }) async {
    final r = await _dio.get(
      '/api/alunos/$alunoId/avaliacoes',
      queryParameters: {'page': page, 'size': size},
    );
    return avaliacoesPaginaFromResponse(r.data);
  }

  /// Até 7 pesos mais recentes, andando páginas newest-first.
  Future<List<double>> listarPesoHistorico(int alunoId) async {
    final paginas = <AvaliacoesPagina>[];
    for (var page = 0; page < 5; page++) {
      final pagina = await listarPagina(alunoId, page: page, size: 100);
      paginas.add(pagina);
      final collected = pesosHistoricoFromPaginas(paginas);
      if (collected.length >= 7 || !pagina.hasNext) return collected;
    }
    return pesosHistoricoFromPaginas(paginas);
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
