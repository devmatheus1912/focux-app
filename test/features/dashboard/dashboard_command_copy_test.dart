import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_command_copy.dart';

void main() {
  test('formata acao e nomes do radar Focux', () {
    expect(
      dashboardFormatActionCopy('Proxima acao: retomar treino'),
      'Próxima ação: retomar treino',
    );
    expect(
      dashboardFormatActionCopy('Radar Focux: thales'),
      'Radar Focux: Thales',
    );
    expect(dashboardRadarStudentName('Radar Focux: lucas andrade'), 'Lucas Andrade');
    expect(
      dashboardPriorityBadgeLabel(prioridade: 'P0', sla: 'Hoje'),
      'P0',
    );
    expect(
      dashboardClampActionCopy('`Nathalia` clicou 3 vezes em mapa corporal'),
      'Nathalia mapa corporal',
    );
    expect(
      dashboardFormatCountCopy('1 cobranças pendentes'),
      '1 cobrança pendente',
    );
    expect(
      dashboardFormatCountCopy('3 cobrancas pendentes'),
      '3 cobranças pendentes',
    );
    final clamped = dashboardClampActionCopy(
      'Nathalia ainda não completou o mapa corporal — vale lembrar hoje. Próxima ação: Completar mapa corporal.',
    );
    expect(clamped.endsWith('…'), isTrue);
    expect(clamped.length, lessThanOrEqualTo(73));
    expect(clamped, isNot(contains('Próxima ação')));
    expect(
      dashboardClampActionCopy('Nathalia · mapa corporal'),
      'Nathalia · mapa corporal',
    );
  });
}
