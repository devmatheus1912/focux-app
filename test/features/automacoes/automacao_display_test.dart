import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/automacoes/utils/automacao_display.dart';

void main() {
  test('chips e contagem', () {
    expect(automacaoChipLabel(AutomacaoChip.todos), 'Todos');
    expect(automacaoChipLabel(AutomacaoChip.templates), 'Templates');
    expect(automacaoChipLabel(AutomacaoChip.ativos), 'Ativos');
    expect(automacaoCountLabel(templates: 0, fluxos: 0), 'Nenhuma automação');
    expect(automacaoCountLabel(templates: 1, fluxos: 0), '1 automação');
    expect(automacaoCountLabel(templates: 2, fluxos: 1), '3 automações');
  });

  test('gatilho e status em PT-BR', () {
    expect(automacaoTriggerLabel('NOVO_ALUNO'), 'Novo aluno');
    expect(automacaoTriggerLabel('ALUNO_CRIADO'), 'Novo aluno');
    expect(automacaoTriggerLabel('DIAS_SEM_CHECKIN'), '4 dias sem treinar');
    expect(automacaoTriggerLabel(''), 'Gatilho');
    expect(automacaoLogStatusLabel('ATIVO'), 'Em andamento');
    expect(automacaoLogStatusLabel('CONCLUIDO'), 'Concluído');
    expect(automacaoFluxoStatusLabel(ativo: true), 'Ativo');
    expect(automacaoFluxoStatusLabel(ativo: false), 'Pausado');
    expect(
      automacaoLogSubtitle(status: 'ATIVO', passoAtual: 0),
      'Em andamento · passo 1',
    );
  });

  test('gatilhos novos, status de falha e entregas no histórico', () {
    expect(automacaoTriggerLabel('ALUNO_VIA_LEAD'), 'Interessado virou aluno');
    expect(automacaoTriggerLabel('RECORDE_PESSOAL'), 'Novo recorde');
    expect(automacaoLogStatusLabel('ERRO'), 'Falhou');
    expect(automacaoLogStatusLabel('CANCELADO'), 'Cancelado');
    expect(
      automacaoLogSubtitle(
        status: 'ATIVO',
        passoAtual: 2,
        entregasOk: 2,
        entregasFalha: 1,
      ),
      'Em andamento · passo 3 · 2 enviadas · 1 falhou',
    );
    expect(automacaoLogComProblema(status: 'ERRO', entregasFalha: 0), isTrue);
    expect(automacaoLogComProblema(status: 'ATIVO', entregasFalha: 1), isTrue);
    expect(automacaoLogComProblema(status: 'CONCLUIDO', entregasFalha: 0), isFalse);
    expect(automacaoPausarConfirmMessage(), contains('meio do fluxo'));
  });

  test('busca casa nome, descrição e gatilho', () {
    expect(
      automacaoMatchesQuery(
        nome: 'Boas-vindas',
        descricao: 'Mensagem no primeiro dia',
        triggerTipo: 'NOVO_ALUNO',
        query: 'bem',
      ),
      isFalse,
    );
    expect(
      automacaoMatchesQuery(
        nome: 'Boas-vindas',
        descricao: 'Mensagem no primeiro dia',
        triggerTipo: 'NOVO_ALUNO',
        query: 'primeiro',
      ),
      isTrue,
    );
    expect(
      automacaoMatchesQuery(
        nome: 'Cobrança',
        descricao: null,
        triggerTipo: 'INADIMPLENCIA',
        query: 'inadimpl',
      ),
      isTrue,
    );
  });
}
