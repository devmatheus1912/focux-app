import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno_hero_signal.dart';

void main() {
  group('alunoHeroContextLine', () {
    test('drops redundant risk label when metric panel shows it', () {
      expect(
        alunoHeroContextLine(
          const AlunoHeroPrimarySignal(
            label: 'Risco operacional',
            value: 'Alto',
          ),
          'Priorize contato hoje',
        ),
        'Priorize contato hoje',
      );
    });

    test('drops redundant aderência label when caption already says it', () {
      expect(
        alunoHeroContextLine(
          const AlunoHeroPrimarySignal(
            label: alunoHeroAderenciaLabel,
            value: '74',
            suffix: '%',
          ),
          'Aderência baixa em 30 dias — reforce o hábito',
        ),
        'Aderência baixa em 30 dias — reforce o hábito',
      );
    });

    test('keeps metric label for other signals', () {
      expect(
        alunoHeroContextLine(
          const AlunoHeroPrimarySignal(label: 'Sem treino', value: '5'),
          '5 dias parado — vale check-in',
        ),
        'Sem treino · 5 dias parado — vale check-in',
      );
    });
  });

  group('alunoHeroIdentitySubtitle', () {
    test('contact priority shows objective only', () {
      expect(
        alunoHeroIdentitySubtitle(
          compactContactPriority: true,
          objectiveDefined: true,
          objective: 'Hipertrofia',
          contextLine: 'Priorize contato hoje',
        ),
        'Hipertrofia',
      );
    });

    test('normal mode keeps objective and context', () {
      expect(
        alunoHeroIdentitySubtitle(
          compactContactPriority: false,
          objectiveDefined: true,
          objective: 'Hipertrofia',
          contextLine: 'Priorize contato hoje',
        ),
        'Hipertrofia · Priorize contato hoje',
      );
    });

    test('undefined objective keeps context only', () {
      expect(
        alunoHeroIdentitySubtitle(
          compactContactPriority: false,
          objectiveDefined: false,
          objective: 'Sem objetivo',
          contextLine: 'Priorize contato hoje',
        ),
        'Priorize contato hoje',
      );
    });
  });

  group('alunoHeroStatusVisual', () {
    Aluno aluno(String status, {bool inad = false, bool risco = false}) =>
        Aluno(
          id: 1,
          nome: 'Nathalia Abrantes',
          email: '',
          status: status,
          inadimplente: inad,
          emRisco: risco,
          riscoNivel: risco ? 'ALTO' : null,
        );

    test('Bloqueado vence inadimplência e risco', () {
      expect(
        alunoHeroStatusVisual(
          aluno('BLOQUEADO', inad: true, risco: true),
        ).label,
        'Bloqueado',
      );
    });

    test('Inativo não mostra Em risco', () {
      expect(
        alunoHeroStatusVisual(aluno('INATIVO', risco: true)).label,
        'Inativo',
      );
    });

    test('Ativo em risco segue Em risco', () {
      expect(
        alunoHeroStatusVisual(aluno('ATIVO', risco: true)).label,
        'Em risco',
      );
    });

    test('sinal principal ignora risco de não ativo', () {
      expect(
        alunoHeroPrimarySignal(aluno('INATIVO', risco: true)).label,
        isNot(riscoOperacionalLabel),
      );
    });
  });
}
