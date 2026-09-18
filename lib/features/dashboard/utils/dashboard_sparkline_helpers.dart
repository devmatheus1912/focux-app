import '../../financeiro/data/financeiro_repository.dart';

/// Série de 7 dias vinda do BFF `pulse.checkinsTrend` (hoje-6 … hoje).
List<double> dashboardCheckinsTrendFromPulse(List<int>? raw) {
  if (raw == null || raw.length < 7) return const [];
  return raw.take(7).map((e) => e.toDouble()).toList(growable: false);
}

/// Últimos N meses de receita para sparkline no hero financeiro.
List<double> dashboardReceitaSparklineMensal(
  List<EvolucaoMensalItem> evolucao, {
  int maxPoints = 6,
}) {
  if (evolucao.isEmpty) return const [];
  final slice =
      evolucao.length <= maxPoints
          ? evolucao
          : evolucao.sublist(evolucao.length - maxPoints);
  return slice.map((e) => e.recebido.cents / 100.0).toList(growable: false);
}
