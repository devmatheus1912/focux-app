import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_action_item.dart';
import 'package:focux_app/features/dashboard/utils/hoje_personal_card.dart';
import 'package:focux_app/features/onboarding/data/onboarding_status_data.dart';
import 'package:focux_app/features/onboarding/data/setup_steps_catalog.dart';

CommandActionItem _acao(String titulo, String frase, {String rota = '/alunos/1'}) {
  return CommandActionItem(
    icon: 'users',
    title: titulo,
    subtitle: frase,
    route: rota,
    tone: CommandActionTone.primary,
  );
}

SetupStepCatalogEntry _passo() => SetupStepCatalogEntry(
  id: 'primeiro-aluno',
  title: 'Cadastre seu primeiro aluno',
  description: 'Cadastre ou importe da concorrência.',
  icon: 'person_add',
  actionRoute: '/alunos/novo',
  estimatedMinutes: 2,
  isDone: (OnboardingStatusData d) => d.primeiroAlunoAdicionado,
);

void main() {
  test('sem aluno, o card é o próximo passo de setup', () {
    final card = hojePersonalCard(
      acoes: [_acao('Contato hoje', 'Hugo está no radar')],
      temAluno: false,
      proximoPasso: _passo(),
    );

    expect(card.titulo, 'Cadastre seu primeiro aluno');
    expect(card.frase, 'Cadastre ou importe da concorrência.');
    expect(card.botao, 'Cadastre seu primeiro aluno');
    expect(card.rota, '/alunos/novo');
  });

  test('com ações, o card é a primeira da fila', () {
    final card = hojePersonalCard(
      acoes: [
        _acao('Hugo', 'Contato agora'),
        _acao('Cobrança', '2 pendências', rota: '/financeiro'),
      ],
      temAluno: true,
      proximoPasso: _passo(),
    );

    expect(card.titulo, 'Hugo');
    expect(card.frase, 'Contato agora');
    expect(card.botao, 'Hugo');
    expect(card.rota, '/alunos/1');
  });

  test('com aluno, criar oportunidade não ocupa a Hoje', () {
    final card = hojePersonalCard(
      acoes: [
        const CommandActionItem(
          icon: 'plus',
          title: 'Criar próxima oportunidade',
          subtitle: 'Aluno, treino ou lead antes do pico',
          route: '/alunos/novo',
          tone: CommandActionTone.primary,
          actionKey: kCommandActionCriarOportunidade,
        ),
      ],
      temAluno: true,
      proximoPasso: _passo(),
    );

    expect(card.titulo, 'Operação sob controle');
    expect(card.frase, 'Nada para fazer agora.');
    expect(card.botao, isNull);
  });

  test('fila vazia não tem botão', () {
    final card = hojePersonalCard(
      acoes: const [],
      temAluno: true,
      proximoPasso: _passo(),
    );

    expect(card.titulo, 'Operação sob controle');
    expect(card.frase, 'Nada para fazer agora.');
    expect(card.botao, isNull);
    expect(card.rota, isNull);
  });

  test('sem aluno e sem passo, a fila vazia também não tem botão', () {
    final card = hojePersonalCard(
      acoes: const [],
      temAluno: false,
      proximoPasso: null,
    );

    expect(card.titulo, 'Operação sob controle');
    expect(card.botao, isNull);
  });
}
