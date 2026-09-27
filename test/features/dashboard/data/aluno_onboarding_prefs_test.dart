import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_onboarding_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('alunoAgendaSemanaKey', () {
    test('qualquer dia da semana cai na segunda', () {
      expect(alunoAgendaSemanaKey(DateTime(2026, 9, 21)), '2026-09-21');
      expect(alunoAgendaSemanaKey(DateTime(2026, 9, 24, 23, 59)), '2026-09-21');
      expect(alunoAgendaSemanaKey(DateTime(2026, 9, 27)), '2026-09-21');
    });

    test('atravessa mês e ano', () {
      expect(alunoAgendaSemanaKey(DateTime(2026, 10, 2)), '2026-09-28');
      expect(alunoAgendaSemanaKey(DateTime(2027, 1, 1)), '2026-12-28');
    });
  });

  group('agenda conferida', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('vale só para a semana em que foi marcada', () async {
      await markAlunoAgendaReviewed(now: DateTime(2026, 9, 22));
      expect(await isAlunoAgendaReviewed(now: DateTime(2026, 9, 27)), isTrue);
      expect(await isAlunoAgendaReviewed(now: DateTime(2026, 9, 28)), isFalse);
    });

    test('marcar apaga a chave antiga sem semana', () async {
      SharedPreferences.setMockInitialValues({
        'aluno_agenda_reviewed_v1': true,
      });
      expect(await isAlunoAgendaReviewed(now: DateTime(2026, 9, 27)), isFalse);
      await markAlunoAgendaReviewed(now: DateTime(2026, 9, 27));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('aluno_agenda_reviewed_v1'), isFalse);
    });

    test('logout limpa as chaves locais do aluno', () {
      expect(alunoOnboardingPrefKeys, contains(kAlunoAgendaReviewedKey));
      expect(alunoOnboardingPrefKeys, contains('aluno_agenda_reviewed_v1'));
      expect(alunoOnboardingPrefKeys, contains(kAlunoNpsAdiadoEmKey));
    });
  });

  group('NPS adiado', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('"Depois" segura a pergunta por 7 dias', () async {
      expect(await isAlunoNpsAdiado(now: DateTime(2026, 9, 27)), isFalse);
      await adiarAlunoNps(now: DateTime(2026, 9, 27, 22));
      expect(await isAlunoNpsAdiado(now: DateTime(2026, 10, 3, 23)), isTrue);
      expect(await isAlunoNpsAdiado(now: DateTime(2026, 10, 4)), isFalse);
    });

    test('valor ruim não bloqueia', () {
      expect(alunoNpsAdiado('x', DateTime(2026, 9, 27)), isFalse);
      expect(alunoNpsAdiado(null, DateTime(2026, 9, 27)), isFalse);
    });
  });
}
