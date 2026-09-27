import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_onboarding_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('agenda vista', () {
    final quarta = DateTime(2026, 9, 30, 18);
    final sexta = DateTime(2026, 10, 2, 7, 30);

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('vale para o horário visto; o seguinte volta a pedir', () async {
      expect(alunoAgendaVista(await readAlunoAgendaVista(), quarta), isFalse);
      await markAlunoAgendaReviewed(quarta);
      final vista = await readAlunoAgendaVista();
      expect(alunoAgendaVista(vista, quarta), isTrue);
      expect(alunoAgendaVista(vista, sexta), isFalse);
      expect(alunoAgendaVista(vista, null), isFalse);
    });

    test('sem horário conhecido não marca nada', () async {
      await markAlunoAgendaReviewed(null);
      expect(await readAlunoAgendaVista(), isNull);
    });

    test('marcar apaga as chaves antigas por semana', () async {
      SharedPreferences.setMockInitialValues({
        'aluno_agenda_reviewed_v1': true,
        'aluno_agenda_reviewed_week_v2': '2026-09-21',
      });
      await markAlunoAgendaReviewed(quarta);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('aluno_agenda_reviewed_v1'), isFalse);
      expect(prefs.containsKey('aluno_agenda_reviewed_week_v2'), isFalse);
    });

    test('logout limpa as chaves locais do aluno', () {
      expect(alunoOnboardingPrefKeys, contains(kAlunoAgendaVistaKey));
      expect(alunoOnboardingPrefKeys, contains('aluno_agenda_reviewed_v1'));
      expect(alunoOnboardingPrefKeys, contains('aluno_agenda_reviewed_week_v2'));
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
