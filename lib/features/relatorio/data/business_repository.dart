import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/money/fx_money.dart';

class BusinessSnapshot {
  final double mrrAtual;
  final double mrrAnterior;
  final double mrrPrevisto;
  final double ndrPct;
  final double arpa;
  final double ltvProxy;
  final int alunosAtivos;
  final int alunosTotal;
  final int inadimplentes;
  final double dunningRecoveryPct;
  final int dunningAbertas;
  final int pqlScore;
  final String pqlClassificacao;

  BusinessSnapshot({
    required this.mrrAtual,
    required this.mrrAnterior,
    required this.mrrPrevisto,
    required this.ndrPct,
    required this.arpa,
    required this.ltvProxy,
    required this.alunosAtivos,
    required this.alunosTotal,
    required this.inadimplentes,
    required this.dunningRecoveryPct,
    required this.dunningAbertas,
    required this.pqlScore,
    required this.pqlClassificacao,
  });

  factory BusinessSnapshot.fromJson(Map<String, dynamic> j) => BusinessSnapshot(
    mrrAtual: FxMoney.reais(j['mrrAtual']),
    mrrAnterior: FxMoney.reais(j['mrrAnterior']),
    mrrPrevisto: FxMoney.reais(j['mrrPrevisto']),
    ndrPct: (j['ndrPct'] as num?)?.toDouble() ?? 0,
    arpa: FxMoney.reais(j['arpa']),
    ltvProxy: FxMoney.reais(j['ltvProxy']),
    alunosAtivos: (j['alunosAtivos'] as num?)?.toInt() ?? 0,
    alunosTotal: (j['alunosTotal'] as num?)?.toInt() ?? 0,
    inadimplentes: (j['inadimplentes'] as num?)?.toInt() ?? 0,
    dunningRecoveryPct: (j['dunningRecoveryPct'] as num?)?.toDouble() ?? 0,
    dunningAbertas: (j['dunningAbertas'] as num?)?.toInt() ?? 0,
    pqlScore: (j['pqlScore'] as num?)?.toInt() ?? 0,
    pqlClassificacao: j['pqlClassificacao'] as String? ?? 'EARLY',
  );
}

class BusinessRepository {
  final Dio _dio;
  BusinessRepository(ApiClient c) : _dio = c.dio;

  Future<BusinessSnapshot> snapshot() async {
    final r = await _dio.get('/api/relatorio/business');
    return BusinessSnapshot.fromJson(r.data as Map<String, dynamic>);
  }
}
