import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/relatorio/utils/business_reports_display.dart';

void main() {
  test('businessNdrStatus e PQL', () {
    expect(businessNdrStatus(110), 'Os mesmos alunos pagam mais');
    expect(businessNdrStatus(100), 'Os mesmos alunos pagam igual');
    expect(businessNdrStatus(90), 'Os mesmos alunos pagam menos');
    expect(businessNdrStatus(null), 'Sem mês anterior para comparar');
    expect(businessNdrAjuda, contains('Aluno novo não entra'));
    expect(businessArpaAjuda, contains('alunos com cobrança'));
    expect(businessLtvAjuda, contains('36 meses'));
    expect(businessNdrRuim(99.9), isTrue);
    expect(businessNdrRuim(null), isFalse);
    expect(businessPqlLabel('EARLY'), 'Início');
    expect(businessPqlLabel('NURTURE'), 'Nutrir');
    expect(businessPqlLabel('PQL'), 'Qualificado');
    expect(businessPqlLabel('PRIORIDADE'), 'Prioridade');
  });

  test('percentual, ARPA e LTV', () {
    expect(businessPctLabel(62.5), '62,5%');
    expect(businessPctLabel(null), '—');
    expect(businessArpaHint(1), 'Faturado ÷ 1 aluno com cobrança');
    expect(businessArpaHint(4), 'Faturado ÷ 4 alunos com cobrança');
    expect(businessLtvHint(12, null), 'Média por aluno × 12 meses (sem histórico)');
    expect(businessLtvHint(2.5, 40), 'Média × 2,5 meses · saída 40,0% no mês');
  });

  test('businessDunningFalhasLabel pluraliza', () {
    expect(businessDunningFalhasLabel(0), 'Nenhuma aberta');
    expect(businessDunningFalhasLabel(1), '1 falha aberta');
    expect(businessDunningFalhasLabel(4), '4 falhas abertas');
    expect(businessComoCalculamos, contains('Recebido'));
    expect(businessAlunosLabel(3, 10), '3 de 10 alunos ativos');
    expect(businessAlunosLabel(1, 1), '1 de 1 aluno ativo');
    expect(businessRecuperacaoLabel(0, 0), 'Nenhuma aberta');
    expect(businessRecuperacaoLabel(50, 2), '50,0% recuperado · 2 falhas abertas');
    expect(businessTemInadimplencia(2), isTrue);
    expect(businessTemDunning(0), isFalse);
  });
}
