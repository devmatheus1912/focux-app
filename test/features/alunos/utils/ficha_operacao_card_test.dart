import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';
import 'package:focux_app/features/alunos/utils/ficha_operacao_card.dart';

OperacaoStickyAction _sticky(String label, OperacaoStickyDestination destino) {
  return OperacaoStickyAction(
    label: label,
    icon: Icons.circle_outlined,
    destination: destino,
  );
}

void main() {
  test('com texto, o card é o rótulo e a frase é o texto', () {
    final sticky = _sticky('Retomar contato', OperacaoStickyDestination.chat);
    final card = fichaOperacaoCard(
      sticky: sticky,
      textoProximaAcao: '  Hugo sumiu esta semana.  ',
    );

    expect(card.titulo, 'Retomar contato');
    expect(card.frase, 'Hugo sumiu esta semana.');
    expect(card.botao, 'Retomar contato');
    expect(card.temBotao, isTrue);
    expect(card.sticky.destination, OperacaoStickyDestination.chat);
  });

  test('sem texto e com mensalidade, o botão cobra', () {
    final card = fichaOperacaoCard(
      sticky: _sticky('Cobrar mensalidade', OperacaoStickyDestination.financeiro),
      textoProximaAcao: '   ',
    );

    expect(card.titulo, 'Cobrar mensalidade');
    expect(card.frase, 'A mensalidade está em aberto.');
    expect(card.botao, 'Cobrar mensalidade');
  });

  test('sem texto e com chat, a frase é o contato', () {
    final card = fichaOperacaoCard(
      sticky: _sticky('Abrir chat', OperacaoStickyDestination.chat),
      textoProximaAcao: null,
    );

    expect(card.titulo, 'Abrir chat');
    expect(card.frase, 'O contato é o próximo passo.');
    expect(card.botao, 'Abrir chat');
  });

  test('sem texto e com tarefa, a frase avisa a tarefa', () {
    final card = fichaOperacaoCard(
      sticky: _sticky('Ver tarefa', OperacaoStickyDestination.commandCenter),
      textoProximaAcao: null,
    );

    expect(card.titulo, 'Ver tarefa');
    expect(card.frase, 'Tem uma tarefa aberta.');
    expect(card.botao, 'Ver tarefa');
  });

  test('sem texto e sem esses casos, não há botão', () {
    final card = fichaOperacaoCard(
      sticky: _sticky('Ver próxima ação', OperacaoStickyDestination.commandCenter),
      textoProximaAcao: null,
    );

    expect(card.titulo, 'Ver próxima ação');
    expect(card.frase, 'Nada urgente nesta ficha.');
    expect(card.botao, isNull);
    expect(card.temBotao, isFalse);
  });
}
