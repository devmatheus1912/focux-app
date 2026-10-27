import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/constants/alunos_list_filters.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/alunos_list_utils.dart';

void main() {
  group('shouldShowAlunoListBadge', () {
    test('oculta Ativo sempre', () {
      expect(shouldShowAlunoListBadge('Ativo', AlunoFiltro.todos), isFalse);
    });

    test('oculta Atenção alta quando filtro risco', () {
      expect(
        shouldShowAlunoListBadge('Atenção alta', AlunoFiltro.risco),
        isFalse,
      );
    });

    test('oculta Atenção alta em triagem todos + banner ativo', () {
      expect(
        shouldShowAlunoListBadge(
          'Atenção alta',
          AlunoFiltro.todos,
          triageContextActive: true,
        ),
        isFalse,
      );
    });

    test('oculta Atenção alta em convites', () {
      expect(
        shouldShowAlunoListBadge('Atenção alta', AlunoFiltro.novos),
        isFalse,
      );
    });

    test('oculta Atenção alta em contato hoje', () {
      expect(
        shouldShowAlunoListBadge('Atenção alta', AlunoFiltro.contatoHoje),
        isFalse,
      );
    });

    test('mostra Inadimplente fora do filtro inadimplentes', () {
      expect(
        shouldShowAlunoListBadge('Inadimplente', AlunoFiltro.todos),
        isTrue,
      );
    });
  });

  group('alunoListStatusBadge', () {
    test('prioriza inadimplência', () {
      final badge = alunoListStatusBadge(
        Aluno(
          id: 1,
          nome: 'Ana',
          email: 'a@test.com',
          status: 'ATIVO',
          statusFinanceiro: 'INADIMPLENTE',
          inadimplente: true,
        ),
        false,
      );
      expect(badge.label, 'Inadimplente');
    });

    test('marca risco alto só com nivel ALTO', () {
      final badge = alunoListStatusBadge(
        Aluno(
          id: 2,
          nome: 'Bruno',
          email: 'b@test.com',
          status: 'ATIVO',
          emRisco: true,
          riscoNivel: 'ALTO',
        ),
        true,
      );
      expect(badge.label, 'Atenção alta');
    });

    test('marca risco medio quando emRisco sem ALTO', () {
      final badge = alunoListStatusBadge(
        Aluno(
          id: 3,
          nome: 'Carla',
          email: 'c@test.com',
          status: 'ATIVO',
          emRisco: true,
          riscoNivel: 'MEDIO',
        ),
        true,
      );
      expect(badge.label, 'Atenção média');
    });

    test('Bloqueado vence inadimplência e risco', () {
      final badge = alunoListStatusBadge(
        Aluno(
          id: 4,
          nome: 'Duda',
          email: 'd@test.com',
          status: 'BLOQUEADO',
          inadimplente: true,
          statusFinanceiro: 'INADIMPLENTE',
          emRisco: true,
          riscoNivel: 'ALTO',
        ),
        false,
      );
      expect(badge.label, 'Bloqueado');
    });

    test('Inativo nunca mostra risco', () {
      final badge = alunoListStatusBadge(
        Aluno(
          id: 5,
          nome: 'Edu',
          email: 'e@test.com',
          status: 'INATIVO',
          emRisco: true,
          riscoNivel: 'ALTO',
        ),
        false,
      );
      expect(badge.label, 'Inativo');
    });

    test('Inadimplente ainda vence Inativo', () {
      final badge = alunoListStatusBadge(
        Aluno(
          id: 6,
          nome: 'Fê',
          email: 'f@test.com',
          status: 'INATIVO',
          inadimplente: true,
        ),
        false,
      );
      expect(badge.label, 'Inadimplente');
    });
  });

  group('alunosListVisiveis', () {
    final ativo = Aluno(id: 1, nome: 'Ana', email: '', status: 'ATIVO');
    final pausado = Aluno(id: 2, nome: 'Bia', email: '', status: 'INATIVO');
    final bloqueado = Aluno(
      id: 3,
      nome: 'Caio',
      email: '',
      status: 'BLOQUEADO',
    );
    final ativo2 = Aluno(id: 4, nome: 'Davi', email: '', status: 'ATIVO');

    test('Inativos traz pausados e bloqueados', () {
      expect(
        alunosListVisiveis([
          ativo,
          pausado,
          bloqueado,
          ativo2,
        ], filtro: AlunoFiltro.inativos).map((a) => a.id),
        [2, 3],
      );
    });

    test('Todos em prioridade manda não ativos para o fim', () {
      expect(
        alunosListVisiveis([
          pausado,
          ativo,
          bloqueado,
          ativo2,
        ], filtro: AlunoFiltro.todos).map((a) => a.id),
        [1, 4, 2, 3],
      );
    });

    test('Nome A-Z mantém a ordem do servidor', () {
      expect(
        alunosListVisiveis(
          [pausado, ativo],
          filtro: AlunoFiltro.todos,
          ordenacao: AlunoOrdenacao.nome,
        ).map((a) => a.id),
        [2, 1],
      );
    });

    test('contagem do chip usa stats ou a lista completa', () {
      expect(
        alunosInativosCount(
          totalInativos: 7,
          carregados: [ativo],
          filtro: AlunoFiltro.ativos,
          temMaisPaginas: true,
        ),
        7,
      );
      expect(
        alunosInativosCount(
          totalInativos: null,
          carregados: [ativo, pausado, bloqueado],
          filtro: AlunoFiltro.todos,
          temMaisPaginas: false,
        ),
        2,
      );
      expect(
        alunosInativosCount(
          totalInativos: null,
          carregados: [ativo],
          filtro: AlunoFiltro.ativos,
          temMaisPaginas: false,
        ),
        isNull,
      );
    });
  });

  group('alunosExclusaoFalhaMessage', () {
    test('singular com motivo', () {
      expect(
        alunosExclusaoFalhaMessage(
          falhas: 1,
          total: 1,
          primeiroErro: 'Sem conexão.',
        ),
        '1 de 1 não pôde ser excluído: Sem conexão.',
      );
    });

    test('plural sem motivo', () {
      expect(
        alunosExclusaoFalhaMessage(falhas: 2, total: 3),
        '2 de 3 não puderam ser excluídos.',
      );
    });
  });

  group('adherenceActivityLabel', () {
    test('some o rótulo quando não há treinos em 7 dias', () {
      expect(alunoWeeklyCheckinsLabel(0), isEmpty);
    });

    test('contagem diz a janela de 7 dias, não a semana', () {
      expect(alunoWeeklyCheckinsLabel(1), '1 treino em 7 dias');
      expect(alunoWeeklyCheckinsLabel(3), '3 treinos em 7 dias');
    });
  });

  group('showAlunosBulkPayCta', () {
    test('some se ninguém está em atraso', () {
      expect(
        showAlunosBulkPayCta([
          Aluno(id: 1, nome: 'Ana', email: 'a@test.com', status: 'ATIVO'),
        ], temFinanceiro: true),
        isFalse,
      );
    });

    test('FREE nunca mostra, mesmo com inadimplente', () {
      expect(
        showAlunosBulkPayCta([
          Aluno(
            id: 1,
            nome: 'Bia',
            email: 'b@test.com',
            status: 'ATIVO',
            inadimplente: true,
            statusFinanceiro: 'INADIMPLENTE',
          ),
        ], temFinanceiro: false),
        isFalse,
      );
    });

    test('mostra se o plano tem financeiro e algum está inadimplente', () {
      expect(
        showAlunosBulkPayCta([
          Aluno(id: 1, nome: 'Ana', email: 'a@test.com', status: 'ATIVO'),
          Aluno(
            id: 2,
            nome: 'Bia',
            email: 'b@test.com',
            status: 'ATIVO',
            inadimplente: true,
            statusFinanceiro: 'INADIMPLENTE',
          ),
        ], temFinanceiro: true),
        isTrue,
      );
    });
  });

  group('filtrosVisiveis', () {
    List<AlunoFiltro> visiveis({
      AlunoFiltro selecionado = AlunoFiltro.todos,
      Map<AlunoFiltro, int?> contagens = const {},
      bool financeiro = true,
    }) => filtrosVisiveis(
      selecionado: selecionado,
      contagens: contagens,
      temFinanceiro: financeiro,
    );

    test('Todos e Ativos ficam sempre', () {
      final v = visiveis(contagens: {
        AlunoFiltro.contatoHoje: 0,
        AlunoFiltro.inadimplentes: 0,
        AlunoFiltro.risco: 0,
        AlunoFiltro.novos: 0,
        AlunoFiltro.inativos: 0,
      });
      expect(v, [AlunoFiltro.todos, AlunoFiltro.ativos]);
    });

    test('chip com contagem aparece, na ordem de sempre', () {
      final v = visiveis(contagens: {
        AlunoFiltro.contatoHoje: 1,
        AlunoFiltro.inadimplentes: 2,
        AlunoFiltro.risco: 1,
        AlunoFiltro.novos: 3,
        AlunoFiltro.inativos: 4,
      });
      expect(v, [
        AlunoFiltro.todos,
        AlunoFiltro.contatoHoje,
        AlunoFiltro.ativos,
        AlunoFiltro.inadimplentes,
        AlunoFiltro.risco,
        AlunoFiltro.novos,
        AlunoFiltro.inativos,
      ]);
    });

    test('o selecionado fica mesmo com zero', () {
      final v = visiveis(
        selecionado: AlunoFiltro.risco,
        contagens: {AlunoFiltro.risco: 0},
      );
      expect(v, contains(AlunoFiltro.risco));
    });

    test('contagem desconhecida (null) mostra o chip', () {
      expect(
        visiveis(contagens: {AlunoFiltro.inativos: null}),
        contains(AlunoFiltro.inativos),
      );
    });

    test('sem financeiro, Em atraso não aparece', () {
      final v = visiveis(
        financeiro: false,
        contagens: {AlunoFiltro.inadimplentes: 5},
      );
      expect(v, isNot(contains(AlunoFiltro.inadimplentes)));
    });
  });

  group('linhaDoCard', () {
    Aluno aluno({
      String? objetivo,
      bool contaAtiva = true,
      int? dias,
      String status = 'ATIVO',
    }) => Aluno(
      id: 1,
      nome: 'Ana',
      email: 'ana@x.com',
      status: status,
      objetivo: objetivo,
      contaAtiva: contaAtiva,
      diasSemTreino: dias,
    );

    test('convite pendente vem primeiro', () {
      final l = linhaDoCard(
        aluno(contaAtiva: false, dias: 9, objetivo: 'Força'),
        maskedEmail: 'a***@x.com',
      );
      expect(l.tipo, LinhaDoCardTipo.convite);
      expect(l.texto, 'Ainda não entrou');
    });

    test('parado há 3 dias ou mais vem antes do objetivo', () {
      final l = linhaDoCard(aluno(dias: 9, objetivo: 'Força'), maskedEmail: 'a***@x.com');
      expect(l.tipo, LinhaDoCardTipo.parado);
      expect(l.texto, 'Parado há 9 dias');
    });

    test('objetivo quando está tudo bem', () {
      final l = linhaDoCard(aluno(dias: 1, objetivo: 'hipertrofia'), maskedEmail: 'a***@x.com');
      expect(l.tipo, LinhaDoCardTipo.objetivo);
      expect(l.texto, 'Hipertrofia');
    });

    test('sem objetivo cai no e-mail, nunca em "Objetivo pendente"', () {
      final l = linhaDoCard(aluno(), maskedEmail: 'a***@x.com');
      expect(l.tipo, LinhaDoCardTipo.email);
      expect(l.texto, 'a***@x.com');
      expect(l.texto, isNot(contains('pendente')));
    });

    test('aluno inativo sem conta não é "Ainda não entrou"', () {
      final l = linhaDoCard(
        aluno(contaAtiva: false, status: 'INATIVO'),
        maskedEmail: 'a***@x.com',
      );
      expect(l.tipo, isNot(LinhaDoCardTipo.convite));
    });
  });
}
