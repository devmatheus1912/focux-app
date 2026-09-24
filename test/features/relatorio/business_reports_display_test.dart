import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/relatorio/utils/business_reports_display.dart';

void main() {
  test('businessNdrStatus e PQL', () {
    expect(businessNdrStatus(110), 'Acima do mês passado');
    expect(businessNdrStatus(100), 'Igual ao mês passado');
    expect(businessNdrStatus(90), 'Abaixo do mês passado');
    expect(businessNdrAjuda, contains('começo do mês'));
    expect(businessArpaAjuda, contains('alunos ativos'));
    expect(businessLtvAjuda, contains('× 12'));
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
