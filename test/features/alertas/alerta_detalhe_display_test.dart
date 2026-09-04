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

  test('copy de adiar 24h fala a verdade do snooze', () {
    expect(alertaAdiarCtaLabel(), 'Adiar 24h');
    expect(alertaAdiadoSuccessMessage(), 'Alerta adiado por 24h.');
    expect(alertaEnviarMensagemCtaLabel(), 'Enviar mensagem');
    expect(alertaEnviandoLabel(), 'Enviando…');
    expect(alertaMensagemEnviadaSuccess(), 'Mensagem enviada.');
  });

  test('alertaMensagemDraft prefere sugestão e cai no rascunho com nome', () {
    expect(
      alertaMensagemDraft(alunoNome: 'Ana Silva', sugestao: '  Manda um oi  '),
      'Manda um oi',
    );
    expect(
      alertaMensagemDraft(alunoNome: 'Ana Silva'),
      'Olá Ana! Vi que faz um tempo que não treina. Que tal retomarmos hoje?',
    );
    expect(
      alertaMensagemDraft(alunoNome: '  '),
      'Olá! Vi que faz um tempo que não treina. Que tal retomarmos hoje?',
    );
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
      'sugestaoFonte': 'LOCAL',
      'podeGerarIa': true,
    });
    expect(detalhe.alunoNome, 'Ana Silva');
    expect(detalhe.sugestaoIa, 'Manda um oi');
    expect(detalhe.sugestaoFonte, 'LOCAL');
    expect(detalhe.podeGerarIa, isTrue);
  });

  test('alertaHubSubtitle junta status e freshness', () {
    expect(alertaHubSubtitle(statusFinanceiro: 'ATIVO'), 'Em dia');
    expect(
      alertaHubSubtitle(
        statusFinanceiro: 'INADIMPLENTE',
        freshness: 'Atualizado agora',
      ),
      'Em atraso · Atualizado agora',
    );
  });

  test('alertaCountLabel e como calculamos', () {
    expect(alertaCountLabel(0), 'Nenhum em risco');
    expect(alertaCountLabel(1), '1 aluno em risco');
    expect(alertaCountLabel(3), '3 alunos em risco');
    expect(alertaComoCalculamos, contains('aderência'));
  });

  test('alertaListSubtitle junta contagem e freshness', () {
    expect(alertaListSubtitle(totalRiscos: 2), '2 alunos em risco');
    expect(
      alertaListSubtitle(totalRiscos: 1, freshness: 'Atualizado agora'),
      '1 aluno em risco · Atualizado agora',
    );
  });

  test('alertaMatchesQuery filtra por nome ou motivo', () {
    expect(
      alertaMatchesQuery(
        alunoNome: 'Ana Silva',
        motivos: const ['Sem treino há 10 dias'],
        query: 'ana',
      ),
      isTrue,
    );
    expect(
      alertaMatchesQuery(
        alunoNome: 'Ana Silva',
        motivos: const ['Sem treino há 10 dias'],
        query: 'aderência',
      ),
      isFalse,
    );
    expect(
      alertaMatchesQuery(
        alunoNome: 'Ana Silva',
        motivos: const ['Sem treino há 10 dias'],
        query: 'treino',
      ),
      isTrue,
    );
  });
}
