import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/suporte/utils/suporte_display.dart';

void main() {
  test('suporteSeveridadeLabel cobre o contrato', () {
    expect(suporteSeveridadeValues, ['BAIXA', 'MEDIA', 'ALTA', 'CRITICA']);
    expect(suporteSeveridadeLabel('BAIXA'), 'Baixa');
    expect(suporteSeveridadeLabel('MEDIA'), 'Média');
    expect(suporteSeveridadeLabel('ALTA'), 'Alta');
    expect(suporteSeveridadeLabel('CRITICA'), 'Crítica');
    expect(suporteSeveridadeLabel(null), 'Média');
    expect(suporteSeveridadeLabel('  '), 'Média');
  });
}
