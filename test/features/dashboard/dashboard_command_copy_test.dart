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
      dashboardRadarSheetSubtitle(
        descricao: 'Completar mapa corporal',
        prioridade: 'P1',
        sla: 'Hoje',
      ),
      contains('mapa corporal'),
    );
    expect(
      dashboardFormatCountCopy('1 cobranças pendentes'),
      '1 cobrança pendente',
    );
    expect(
      dashboardFormatCountCopy('3 cobrancas pendentes'),
      '3 cobranças pendentes',
    );
  });
}
