import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/hoje_personal_dia.dart';

void main() {
  test('só entra linha com número e cada uma abre o lugar certo', () {
    final linhas = hojePersonalDia(
      agendaHoje: 2,
      alunosContato: 1,
      mensalidades: 0,
      conversas: 3,
      alunosNaBase: 12,
    );

    expect(linhas.map((l) => l.texto), [
      '2 compromissos hoje',
      '1 aluno para contato',
      '3 conversas sem resposta',
    ]);
    expect(linhas.map((l) => l.rota), [
      '/agenda',
      '/alunos?filtro=contato',
      '/chat/inbox',
    ]);
  });

  test('dia quieto mostra a base, sem inventar pendência', () {
    final linhas = hojePersonalDia(
      agendaHoje: 0,
      alunosContato: 0,
      mensalidades: 0,
      conversas: 0,
      alunosNaBase: 8,
    );

    expect(linhas, hasLength(1));
    expect(linhas.single.texto, '8 alunos na base');
    expect(linhas.single.rota, '/alunos');
  });

  test('sem aluno e sem pendência a lista fica vazia', () {
    expect(
      hojePersonalDia(
        agendaHoje: 0,
        alunosContato: 0,
        mensalidades: 0,
        conversas: 0,
        alunosNaBase: 0,
      ),
      isEmpty,
    );
  });
}
