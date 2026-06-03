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
  });
}
