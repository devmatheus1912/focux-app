import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/constants/alunos_list_filters.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/alunos_list_utils.dart';

void main() {
  group('shouldShowAlunoListBadge', () {
    test('oculta Ativo sempre', () {
      expect(
        shouldShowAlunoListBadge('Ativo', AlunoFiltro.todos),
        isFalse,
      );
    });

    test('oculta Risco alto quando filtro risco', () {
      expect(
        shouldShowAlunoListBadge('Risco alto', AlunoFiltro.risco),
        isFalse,
      );
    });

    test('oculta Risco alto em triagem todos + banner ativo', () {
      expect(
        shouldShowAlunoListBadge(
          'Risco alto',
          AlunoFiltro.todos,
          triageContextActive: true,
        ),
        isFalse,
      );
    });

    test('oculta Risco alto em convites', () {
      expect(
        shouldShowAlunoListBadge('Risco alto', AlunoFiltro.novos),
        isFalse,
      );
    });

    test('oculta Risco alto em contato hoje', () {
      expect(
        shouldShowAlunoListBadge('Risco alto', AlunoFiltro.contatoHoje),
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
      expect(badge.label, 'Risco alto');
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
      expect(badge.label, 'Risco médio');
    });
  });

  group('shouldShowAlunoListOpsLine', () {
    test('mostra dias sem treino mesmo em triagem', () {
      expect(
        shouldShowAlunoListOpsLine(
          adherenceLabel: '12d s/ treino',
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
  });

  group('adherenceActivityLabel', () {
    test('some o rótulo quando não há treinos na semana', () {
      expect(alunoWeeklyCheckinsLabel(0), isEmpty);
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
