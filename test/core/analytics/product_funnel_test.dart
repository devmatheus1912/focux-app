import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/analytics/product_funnel.dart';

void main() {
  test('só aluno_created vira CADASTRO — CHECKIN fica no BE', () {
    expect(productEventToFunnelTipo('aluno_created'), 'CADASTRO');
    expect(productEventToFunnelTipo('dunning_hub_viewed'), isNull);
    expect(productEventToFunnelTipo('checkin'), isNull);
    expect(productEventToFunnelTipo('checkin_hub_viewed'), isNull);
  });

  test('alunoId só sai de props existentes', () {
    expect(funnelAlunoIdFromProps({'alunoId': 12}), 12);
    expect(funnelAlunoIdFromProps({'alunoId': '9'}), 9);
    expect(funnelAlunoIdFromProps({'has_whatsapp': true}), isNull);
    expect(funnelAlunoIdFromProps(null), isNull);
  });
}
