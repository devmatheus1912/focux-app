import '../../checkin/data/checkin_repository.dart';
import '../../financeiro/data/financeiro_repository.dart';

/// Série de 7 dias vinda do BFF `pulse.checkinsTrend` (hoje-6 … hoje).
List<double> dashboardCheckinsTrendFromPulse(List<int>? raw) {
  if (raw == null || raw.length < 7) return const [];
  return raw.take(7).map((e) => e.toDouble()).toList(growable: false);
}

/// Série dos últimos 7 dias (check-ins concluídos por dia).
List<double> dashboardCheckinsSparklineUltimos7Dias(
  List<ExecucaoTreino> items,
) {
  final hoje = DateTime.now();
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  return List<double>.generate(7, (index) {
    final day = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
    ).subtract(Duration(days: 6 - index));
    return items
        .where((e) {
          final concluded = DateTime.tryParse(e.concluidoEm ?? '');
          if (concluded == null) return false;
          return sameDay(concluded.toLocal(), day);
        })
        .length
        .toDouble();
  });
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
