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

    test('marca risco alto', () {
      final badge = alunoListStatusBadge(
        Aluno(
          id: 2,
          nome: 'Bruno',
          email: 'b@test.com',
          status: 'ATIVO',
          emRisco: true,
        ),
        true,
      );
      expect(badge.label, 'Risco alto');
    });
  });

  group('adherenceActivityLabel', () {
    test('some o rótulo quando não há treinos na semana', () {
      expect(alunoWeeklyCheckinsLabel(0), isEmpty);
    });
  });
}
