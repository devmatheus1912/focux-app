import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_day_focus.dart';

void main() {
  test('prioriza cobrança e risco quando há pendências', () {
    final focus = DashboardDayFocus.resolve(
      riscoAlto: 3,
      alunosAtivos: 8,
      checkinsHoje: 0,
      agendaHoje: 0,
      receitaMes: 100,
      vencimentosPendentes: 2,
      riskDominante: true,
    );
    expect(focus.headline, contains('Cobrança'));
  });

  test('prioriza check-ins quando operação parada', () {
    final focus = DashboardDayFocus.resolve(
      riscoAlto: 0,
      alunosAtivos: 5,
      checkinsHoje: 0,
      agendaHoje: 0,
      receitaMes: 500,
      vencimentosPendentes: 0,
      riskDominante: false,
    );
    expect(focus.headline, contains('check-in'));
  });
}
