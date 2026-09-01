import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';
import 'package:focux_app/features/alertas/utils/alerta_detalhe_display.dart';

void main() {
  test('alertaUltimoTreinoLabel formata data BR e vazio', () {
    expect(alertaUltimoTreinoLabel(null), 'Sem treinos');
    expect(alertaUltimoTreinoLabel(''), 'Sem treinos');
    expect(alertaUltimoTreinoLabel('2026-08-31'), '31 de agosto de 2026');
  });

  test('alertaCheckinsLabel pluraliza', () {
    expect(alertaCheckinsLabel(0), 'Nenhum em 30 dias');
    expect(alertaCheckinsLabel(1), '1 em 30 dias');
    expect(alertaCheckinsLabel(8), '8 em 30 dias');
  });

  test('alertaStatusFinanceiroLabel humaniza códigos', () {
    expect(alertaStatusFinanceiroLabel('ATIVO'), 'Em dia');
    expect(alertaStatusFinanceiroLabel('INADIMPLENTE'), 'Em atraso');
    expect(alertaStatusFinanceiroLabel('CANCELADO'), 'Cancelado');
    expect(alertaStatusFinanceiroRuim('INADIMPLENTE'), isTrue);
    expect(alertaStatusFinanceiroRuim('ATIVO'), isFalse);
  });

  test('AlertaDetalhe ignora e-mail no payload', () {
    final detalhe = AlertaDetalhe.fromJson({
      'alunoId': 1,
      'alunoNome': 'Ana Silva',
      'alunoEmail': 'ana@exemplo.com',
      'ultimoTreino': '2026-08-31',
      'checkIns30Dias': 2,
      'statusFinanceiro': 'ATIVO',
      'sugestaoIa': 'Manda um oi',
    });
    expect(detalhe.alunoNome, 'Ana Silva');
    expect(detalhe.sugestaoIa, 'Manda um oi');
  });
}
