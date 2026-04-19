import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class AderenciaData {
  final int diasAnalisados;
  final int treinosConcluidos;
  final int treinosTotal;
  final double taxaAderenciaPercent;

  AderenciaData({
    required this.diasAnalisados,
    required this.treinosConcluidos,
    required this.treinosTotal,
    required this.taxaAderenciaPercent,
  });

  factory AderenciaData.fromJson(Map<String, dynamic> j) => AderenciaData(
        diasAnalisados: j['diasAnalisados'] as int,
        treinosConcluidos: j['treinosConcluidos'] as int,
        treinosTotal: j['treinosTotal'] as int,
        taxaAderenciaPercent: (j['taxaAderenciaPercent'] as num).toDouble(),
      );
}

class ResumoAluno {
  final int alunoId;
  final String alunoNome;
  final int totalTreinos;
  final int treinosConcluidos;
  final String? ultimoTreino;

  ResumoAluno({
    required this.alunoId,
    required this.alunoNome,
    required this.totalTreinos,
    required this.treinosConcluidos,
    this.ultimoTreino,
  });

  factory ResumoAluno.fromJson(Map<String, dynamic> j) => ResumoAluno(
        alunoId: j['alunoId'] as int,
        alunoNome: j['alunoNome'] as String,
        totalTreinos: (j['totalTreinos'] as num).toInt(),
        treinosConcluidos: (j['treinosConcluidos'] as num).toInt(),
        ultimoTreino: j['ultimoTreino'] as String?,
      );
}

class ComparativoPeriodo {
  final double aderenciaAtual;
  final double aderenciaAnterior;
  final double deltaPercent;
  final int checkInsAtual;
  final int checkInsAnterior;

  ComparativoPeriodo({
    required this.aderenciaAtual,
    required this.aderenciaAnterior,
    required this.deltaPercent,
    required this.checkInsAtual,
    required this.checkInsAnterior,
  });

  factory ComparativoPeriodo.fromJson(Map<String, dynamic> j) =>
      ComparativoPeriodo(
        aderenciaAtual: (j['aderenciaAtual'] as num).toDouble(),
        aderenciaAnterior: (j['aderenciaAnterior'] as num).toDouble(),
        deltaPercent: (j['deltaPercent'] as num).toDouble(),
        checkInsAtual: (j['checkInsAtual'] as num).toInt(),
        checkInsAnterior: (j['checkInsAnterior'] as num).toInt(),
      );
}

class ResumoGlobal {
  final double aderenciaMediaGeral;
  final int totalAlunos;
  final List<ResumoAluno> maisComprometidos;
  final List<ResumoAluno> menosComprometidos;

  ResumoGlobal({
    required this.aderenciaMediaGeral,
    required this.totalAlunos,
    required this.maisComprometidos,
    required this.menosComprometidos,
  });

  factory ResumoGlobal.fromJson(Map<String, dynamic> j) => ResumoGlobal(
        aderenciaMediaGeral: (j['aderenciaMediaGeral'] as num).toDouble(),
        totalAlunos: (j['totalAlunos'] as num).toInt(),
        maisComprometidos: (j['maisComprometidos'] as List)
            .map((e) => ResumoAluno.fromJson(e as Map<String, dynamic>))
            .toList(),
        menosComprometidos: (j['menosComprometidos'] as List)
            .map((e) => ResumoAluno.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RelatorioRepository {
  final Dio _dio;

  RelatorioRepository(ApiClient c) : _dio = c.dio;

  Future<AderenciaData> aderencia(int alunoId, {int dias = 30}) async {
    final r = await _dio.get(
      '/api/relatorios/aderencia/$alunoId',
      queryParameters: {'dias': dias},
    );
    return AderenciaData.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<ResumoAluno>> resumo() async {
    final r = await _dio.get('/api/relatorios/resumo');
    return (r.data as List)
        .map((e) => ResumoAluno.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ResumoGlobal> resumoGlobal() async {
    final r = await _dio.get('/api/relatorios/resumo-global');
    return ResumoGlobal.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ComparativoPeriodo> comparativo(int alunoId, {int dias = 30}) async {
    final r = await _dio.get(
      '/api/relatorios/aderencia/$alunoId/comparativo',
      queryParameters: {'dias': dias},
    );
    return ComparativoPeriodo.fromJson(r.data as Map<String, dynamic>);
  }
}
