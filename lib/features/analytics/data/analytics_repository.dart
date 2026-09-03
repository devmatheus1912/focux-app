import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class FunilAtivacao {
  final int cadastrados;
  final int fizeram1Checkin;
  final int fizeram3Checkins;
  final int ativos30Dias;
  final double taxaAtivacao;
  final double taxaEngajamento;
  final double taxaRetencao;

  const FunilAtivacao({
    required this.cadastrados,
    required this.fizeram1Checkin,
    required this.fizeram3Checkins,
    required this.ativos30Dias,
    required this.taxaAtivacao,
    required this.taxaEngajamento,
    required this.taxaRetencao,
  });

  factory FunilAtivacao.fromJson(Map<String, dynamic> j) => FunilAtivacao(
    cadastrados: (j['cadastrados'] as num).toInt(),
    fizeram1Checkin: (j['fizeram1Checkin'] as num).toInt(),
    fizeram3Checkins: (j['fizeram3Checkins'] as num).toInt(),
    ativos30Dias: (j['ativos30Dias'] as num).toInt(),
    taxaAtivacao: (j['taxaAtivacao'] as num).toDouble(),
    taxaEngajamento: (j['taxaEngajamento'] as num).toDouble(),
    taxaRetencao: (j['taxaRetencao'] as num).toDouble(),
  );
}

class WauSemanal {
  final String semana;
  final int usuarios;

  const WauSemanal({required this.semana, required this.usuarios});

  factory WauSemanal.fromJson(Map<String, dynamic> j) => WauSemanal(
    semana: j['semana'] as String,
    usuarios: (j['usuarios'] as num).toInt(),
  );
}

class CohortRetencao {
  final String mesEntrada;
  final int cadastrados;
  final int ativosD7;
  final int ativosD30;
  final double retencaoD7;
  final double retencaoD30;

  const CohortRetencao({
    required this.mesEntrada,
    required this.cadastrados,
    required this.ativosD7,
    required this.ativosD30,
    required this.retencaoD7,
    required this.retencaoD30,
  });

  factory CohortRetencao.fromJson(Map<String, dynamic> j) => CohortRetencao(
    mesEntrada: j['mesEntrada'] as String,
    cadastrados: (j['cadastrados'] as num).toInt(),
    ativosD7: (j['ativosD7'] as num).toInt(),
    ativosD30: (j['ativosD30'] as num).toInt(),
    retencaoD7: (j['retencaoD7'] as num).toDouble(),
    retencaoD30: (j['retencaoD30'] as num).toDouble(),
  );
}

class AnalyticsDashboard {
  final int totalAlunos;
  final int inadimplentes;
  final int wau;
  final int mau;
  final double taxaInadimplencia;
  final double retencaoD7;
  final double retencaoD30;
  final FunilAtivacao? funil;
  final List<WauSemanal> evolucaoWau;
  final List<CohortRetencao> cohort;
  final DateTime? fetchedAt;

  const AnalyticsDashboard({
    required this.totalAlunos,
    required this.inadimplentes,
    required this.wau,
    required this.mau,
    required this.taxaInadimplencia,
    required this.retencaoD7,
    required this.retencaoD30,
    this.funil,
    required this.evolucaoWau,
    required this.cohort,
    this.fetchedAt,
  });

  factory AnalyticsDashboard.fromJson(Map<String, dynamic> j) =>
      AnalyticsDashboard(
        totalAlunos: (j['totalAlunos'] as num).toInt(),
        inadimplentes: (j['inadimplentes'] as num).toInt(),
        wau: (j['wau'] as num).toInt(),
        mau: (j['mau'] as num).toInt(),
        taxaInadimplencia: (j['taxaInadimplencia'] as num).toDouble(),
        retencaoD7: (j['retencaoD7'] as num).toDouble(),
        retencaoD30: (j['retencaoD30'] as num).toDouble(),
        funil:
            j['funil'] != null
                ? FunilAtivacao.fromJson(j['funil'] as Map<String, dynamic>)
                : null,
        evolucaoWau:
            ((j['evolucaoWau'] as List?) ?? [])
                .map((e) => WauSemanal.fromJson(e as Map<String, dynamic>))
                .toList(),
        cohort:
            ((j['cohort'] as List?) ?? [])
                .map((e) => CohortRetencao.fromJson(e as Map<String, dynamic>))
                .toList(),
        fetchedAt: DateTime.tryParse(j['fetchedAt']?.toString() ?? ''),
      );
}

// ─── Repository ──────────────────────────────────────────────────────────────

class AnalyticsRepository {
  final Dio _dio;

  AnalyticsRepository(ApiClient c) : _dio = c.dio;

  Future<AnalyticsDashboard> getDashboard() async {
    final r = await _dio.get('/api/analytics/home');
    return AnalyticsDashboard.fromJson(r.data as Map<String, dynamic>);
  }

  Future<FunilAtivacao> getFunil() async {
    final r = await _dio.get('/api/analytics/funil');
    return FunilAtivacao.fromJson(r.data as Map<String, dynamic>);
  }
}
