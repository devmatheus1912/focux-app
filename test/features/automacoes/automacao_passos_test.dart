import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/automacoes/data/automacao_repository.dart';
import 'package:focux_app/features/automacoes/utils/automacao_display.dart';

void main() {
  const boasVindas = [
    AutomacaoPassoDef(acaoTipo: 'PUSH', config: {'titulo': 'Bem-vindo!', 'corpo': 'Seu personal preparou seu plano.'}),
    AutomacaoPassoDef(acaoTipo: 'WAIT', delayMinutos: 1440),
    AutomacaoPassoDef(acaoTipo: 'PUSH', config: {'titulo': 'Seu treino está no app', 'corpo': 'Bora começar?'}),
    AutomacaoPassoDef(acaoTipo: 'WAIT', delayMinutos: 2880),
    AutomacaoPassoDef(acaoTipo: 'CHAT_TEMPLATE', config: {'mensagem': 'Precisa de ajuda com algum exercício?'}),
  ];

  test('prévia diz quando sai, o canal e que a mensagem vai em nome do personal', () {
    expect(automacaoPassosLinhas(boasVindas), [
      'Na hora: aviso “Bem-vindo! Seu personal preparou seu plano.”',
      '1 dia depois: aviso “Seu treino está no app Bora começar?”',
      '3 dias depois: mensagem no chat, em seu nome: “Precisa de ajuda com algum exercício?”',
    ]);
  });

  test('resumo da linha e cabeçalho', () {
    expect(automacaoResumoPassos(boasVindas), '2 avisos e 1 mensagem em 3 dias');
    expect(automacaoResumoPassos(const []), 'Sem envios');
    expect(automacaoLigadasLabel(ligadas: 1, total: 4), '1 de 4 ligadas');
    expect(automacaoLigadaLabel(null), 'Ligada');
    expect(automacaoLigadaLabel(0), 'Ligada');
    expect(automacaoLigadaLabel(1), 'Ligada · 1 aluno em andamento');
    expect(automacaoLigadaLabel(3), 'Ligada · 3 alunos em andamento');
  });

  test('nome do catálogo atual vale para fluxo antigo', () {
    expect(automacaoNome(templateId: 'ONBOARDING_7D', nomeGravado: 'Onboarding 7 dias'), 'Boas-vindas');
    expect(automacaoNome(templateId: null, nomeGravado: 'Meu fluxo'), 'Meu fluxo');
  });
}
