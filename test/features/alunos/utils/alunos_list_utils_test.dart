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

  group('shouldShowAlunoListOpsLine', () {
    test('mostra dias sem treino mesmo em triagem', () {
      expect(
        shouldShowAlunoListOpsLine(
          adherenceLabel: 'Parado há 12d',
          triageContextActive: true,
          aderenciaPercent: 0,
        ),
        isTrue,
      );
    });

    test('esconde percentual vazio em triagem', () {
      expect(
        shouldShowAlunoListOpsLine(
          adherenceLabel: '',
          triageContextActive: true,
          aderenciaPercent: 0,
        ),
        isFalse,
      );
    });

    test('esconde 0% mesmo fora da triagem', () {
      expect(
        shouldShowAlunoListOpsLine(
          adherenceLabel: '',
          triageContextActive: false,
          aderenciaPercent: 0,
        ),
        isFalse,
      );
    });

    test('esconde percentual em convites', () {
      expect(
        alunoListOpsText(
          adherenceLabel: '',
          triageContextActive: false,
          aderenciaPercent: 72,
          filtro: AlunoFiltro.novos,
        ),
        isEmpty,
      );
    });

    test('mostra percentual fora da triagem', () {
      expect(
        shouldShowAlunoListOpsLine(
          adherenceLabel: '',
          triageContextActive: false,
          aderenciaPercent: 72,
        ),
        isTrue,
      );
    });

    test('percentual diz a janela de 30 dias do servidor', () {
      expect(
        alunoListOpsText(
          adherenceLabel: '',
          triageContextActive: false,
          aderenciaPercent: 72,
        ),
        '72% em 30 dias',
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

  group('showAlunosContatoBanner', () {
    test('mostra quando só parte da base precisa de contato', () {
      expect(
        showAlunosContatoBanner(
          modoSelecao: false,
          filtro: AlunoFiltro.todos,
          contatoCount: 3,
          totalCount: 8,
        ),
        isTrue,
      );
    });

    test('esconde quando 100% da lista é o foco', () {
      expect(
        showAlunosContatoBanner(
          modoSelecao: false,
          filtro: AlunoFiltro.todos,
          contatoCount: 8,
          totalCount: 8,
        ),
        isFalse,
      );
    });

    test('esconde em seleção e fora de todos', () {
      expect(
        showAlunosContatoBanner(
          modoSelecao: true,
          filtro: AlunoFiltro.todos,
          contatoCount: 3,
          totalCount: 8,
        ),
        isFalse,
      );
      expect(
        showAlunosContatoBanner(
          modoSelecao: false,
          filtro: AlunoFiltro.contatoHoje,
          contatoCount: 3,
          totalCount: 8,
        ),
        isFalse,
      );
    });
  });

  group('showAlunosRiscoBanner', () {
    test('some se o banner de contato já está no ar', () {
      expect(
        showAlunosRiscoBanner(
          modoSelecao: false,
          filtro: AlunoFiltro.todos,
          riscoCount: 2,
          totalCount: 8,
          contatoBannerVisible: true,
        ),
        isFalse,
      );
    });

    test('esconde quando risco cobre a base inteira', () {
      expect(
        showAlunosRiscoBanner(
          modoSelecao: false,
          filtro: AlunoFiltro.todos,
          riscoCount: 8,
          totalCount: 8,
          contatoBannerVisible: false,
        ),
        isFalse,
      );
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
}
