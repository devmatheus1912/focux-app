import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/relatorio/utils/business_reports_display.dart';

void main() {
  test('businessNdrStatus e PQL', () {
    expect(businessNdrStatus(110), 'Expansão');
    expect(businessNdrStatus(90), 'Contração');
    expect(businessNdrRuim(99.9), isTrue);
    expect(businessPqlLabel('EARLY'), 'Início');
    expect(businessPqlLabel('NURTURE'), 'Nutrir');
    expect(businessPqlLabel('PQL'), 'Qualificado');
    expect(businessPqlLabel('PRIORIDADE'), 'Prioridade');
  });

  test('businessDunningFalhasLabel pluraliza', () {
    expect(businessDunningFalhasLabel(0), 'Nenhuma aberta');
    expect(businessDunningFalhasLabel(1), '1 falha aberta');
    expect(businessDunningFalhasLabel(4), '4 falhas abertas');
    expect(businessComoCalculamos, contains('Recebido'));
    expect(businessAlunosLabel(3, 10), '3 / 10');
    expect(businessTemInadimplencia(2), isTrue);
    expect(businessTemDunning(0), isFalse);
  });
}
