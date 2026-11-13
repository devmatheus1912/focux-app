import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/habitos/data/habito_repository.dart';
import 'package:focux_app/features/habitos/utils/habitos_display.dart';

ComplianceItem _c(String nome, int feitos, int meta) => ComplianceItem(
  alunoId: nome.hashCode,
  alunoNome: nome,
  checksSemana: feitos,
  compliancePct: 0,
  metaSemana: meta,
);

void main() {
  test('regra numa frase e vezes por semana', () {
    expect(
      habitoRegra(metaSemanal: 5, alunoId: null),
      '5x por semana · Todos os alunos',
    );
    expect(habitoVezesPorSemana(1), '1 vez por semana');
    expect(habitoVezesPorSemana(5), '5 vezes por semana');
    expect(habitoSemanaLinha(3, 7), '3 de 7 esta semana');
  });

  test('esta semana: mais longe da meta primeiro; quem bateu à parte', () {
    final r = habitoOrdenarSemana([
      _c('Ana', 6, 7),
      _c('Bia', 1, 7),
      _c('Caio', 7, 7),
      _c('Duda', 0, 0),
    ]);
    expect(r.pendentes.map((c) => c.alunoNome), ['Bia', 'Ana']);
    expect(r.bateram.map((c) => c.alunoNome), ['Caio']);
  });

  test('subtítulo diz o que pede ação', () {
    expect(
      habitoSubtituloLista(habitos: 0, abaixoDaMeta: 0, temSemana: false),
      'Nenhum hábito',
    );
    expect(
      habitoSubtituloLista(habitos: 2, abaixoDaMeta: 2, temSemana: true),
      '2 alunos abaixo da meta esta semana',
    );
    expect(
      habitoSubtituloLista(habitos: 2, abaixoDaMeta: 0, temSemana: true),
      'Todos em dia esta semana',
    );
    expect(
      habitoSubtituloLista(habitos: 3, abaixoDaMeta: 0, temSemana: false),
      '3 hábitos',
    );
  });

  test('busca só com mais de 6 alunos', () {
    expect(habitoMostraBusca(total: 6, query: ''), isFalse);
    expect(habitoMostraBusca(total: 7, query: ''), isTrue);
    expect(habitoMostraBusca(total: 2, query: 'ana'), isTrue);
  });

  test('marcações recentes e sequência', () {
    expect(habitoChecksLine(null), '');
    expect(habitoChecksLine(const []), 'Nenhuma marcação ainda');
    expect(habitoSequenciaLinha(0), '');
    expect(habitoSequenciaLinha(4), '4 dias seguidos');
  });

  test('sequência por extenso e linha do aluno sem descrição', () {
    expect(habitoSequenciaLabel(0), isNull);
    expect(habitoSequenciaLabel(1), '1 dia seguido');
    expect(habitoSequenciaLabel(5), '5 dias seguidos');
    expect(
      habitoAlunoSubtitle(feitosNaSemana: 1, metaSemanal: 7, streak: 1),
      '1 de 7 esta semana · 1 dia seguido',
    );
    expect(
      habitoDesativadoLinha(metaSemanal: 7),
      'Desativado · 7x por semana · Todos os alunos',
    );
  });
}
