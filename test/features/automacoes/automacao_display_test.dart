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
    expect(automacaoTriggerLabel('checkin'), 'Check-in');
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
