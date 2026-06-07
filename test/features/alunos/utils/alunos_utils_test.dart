import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno_display_utils.dart';
import 'package:focux_app/features/alunos/utils/aluno_hero_signal.dart';
import 'package:focux_app/features/alunos/utils/aluno_media_utils.dart';

void main() {
  group('prettyAlunoObjective', () {
    test('normaliza hipertrofia', () {
      expect(prettyAlunoObjective('HIPERTROFIA'), 'Hipertrofia');
    });

    test('objetivo vazio', () {
      expect(prettyAlunoObjective(null), 'Objetivo pendente');
      expect(alunoObjectiveIsDefined(null), isFalse);
      expect(alunoObjectiveIsDefined('  '), isFalse);
      expect(alunoObjectiveIsDefined('Hipertrofia'), isTrue);
    });

    test('hero fallback avoids teal palette', () {
      final hero = alunoAvatarHeroFallbackColor('Beatriz');
      final list = alunoAvatarFallbackColor('Beatriz', false);
      expect(hero, isNot(equals(list)));
    });
  });

  group('sanitizeOutreachGenderTerms', () {
    test('feminine profile uses juntas', () {
      expect(
        sanitizeOutreachGenderTerms(
          'Quer retomar juntos?',
          genero: 'Feminino',
        ),
        'Quer retomar juntas?',
      );
    });

    test('unknown gender uses inclusive form', () {
      expect(
        sanitizeOutreachGenderTerms('Quer retomar juntos?'),
        'Quer retomar juntos(as)?',
      );
    });
  });

  group('resolveAlunoPhotoUrl', () {
    test('retorna null para vazio', () {
      expect(resolveAlunoPhotoUrl(''), isNull);
    });

    test('preserva URL absoluta', () {
      expect(
        resolveAlunoPhotoUrl('https://cdn.example.com/a.jpg'),
        'https://cdn.example.com/a.jpg',
      );
    });
  });

  group('alunoHeroPrimarySignal', () {
    test('prioriza dias sem treino quando em risco', () {
      final aluno = Aluno(
        id: 1,
        nome: 'Test',
        email: 'test@test.com',
        status: 'ATIVO',
        emRisco: true,
        diasSemTreino: 29,
        aderenciaPercent: 40,
      );
      final signal = alunoHeroPrimarySignal(aluno);
      expect(signal.label, 'Sem treino');
      expect(signal.value, '29');
    });

    test('usa aderência quando rotina ok', () {
      final aluno = Aluno(
        id: 1,
        nome: 'Test',
        email: 'test@test.com',
        status: 'ATIVO',
        diasSemTreino: 1,
        aderenciaPercent: 74,
      );
      final signal = alunoHeroPrimarySignal(aluno);
      expect(signal.label, 'Aderência semanal');
      expect(signal.value, '74');
    });
  });

  group('alunoHeroCaption', () {
    test('caption curta para dias críticos', () {
      final aluno = Aluno(
        id: 1,
        nome: 'Test',
        email: 'test@test.com',
        status: 'ATIVO',
        diasSemTreino: 29,
      );
      final signal = alunoHeroPrimarySignal(aluno);
      expect(
        alunoHeroCaption(aluno, signal),
        'Parado há 29 dias — contato hoje',
      );
    });

    test('caption curta para risco operacional', () {
      final aluno = Aluno(
        id: 1,
        nome: 'Beatriz',
        email: 'b@test.com',
        status: 'ATIVO',
        emRisco: true,
        riscoNivel: 'ALTO',
        aderenciaPercent: 0,
        diasSemTreino: 0,
      );
      final signal = alunoHeroPrimarySignal(aluno);
      expect(signal.label, 'Risco operacional');
      expect(alunoHeroCaption(aluno, signal), 'Priorize contato hoje');
    });
  });

  group('alunoHeroShouldShowStatusBadge', () {
    test('hides em risco badge when risco operacional dominates', () {
      expect(
        alunoHeroShouldShowStatusBadge(
          signal: const AlunoHeroPrimarySignal(
            label: 'Risco operacional',
            value: 'Alto',
          ),
          status: const AlunoHeroStatusVisual(
            label: 'Em risco',
            background: Color(0xFF000000),
            foreground: Color(0xFFFFFFFF),
          ),
        ),
        isFalse,
      );
    });

    test('shows badge when sem treino shares em risco status', () {
      expect(
        alunoHeroShouldShowStatusBadge(
          signal: const AlunoHeroPrimarySignal(
            label: 'Sem treino',
            value: '29',
            suffix: ' dias',
          ),
          status: const AlunoHeroStatusVisual(
            label: 'Em risco',
            background: Color(0xFF000000),
            foreground: Color(0xFFFFFFFF),
          ),
        ),
        isTrue,
      );
    });
  });
}
