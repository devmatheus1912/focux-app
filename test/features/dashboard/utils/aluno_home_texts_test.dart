import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_texts.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_week.dart';
import 'package:focux_app/features/dashboard/utils/aluno_pendencias.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

final _pt = lookupS(const Locale('pt'));
final _en = lookupS(const Locale('en'));
final _hoje = DateTime(2026, 9, 27);

AlunoTodayAction _treino({
  int exercicios = 6,
  bool comeback = false,
  DateTime? prazoFim,
}) => AlunoTodayAction(
  mode: AlunoTodayMode.workoutReady,
  route: '/checkin/executar',
  routeExtra: 7,
  treinoNome: 'Treino A',
  exerciseCount: exercicios,
  comeback: comeback,
  prazoFim: prazoFim,
);

void main() {
  setUpAll(() => initializeDateFormatting());

  group('alunoTodayTexto', () {
    test('todo modo tem texto em pt e en', () {
      for (final mode in AlunoTodayMode.values) {
        final a = AlunoTodayAction(mode: mode, route: '/x');
        for (final s in [_pt, _en]) {
          final t = alunoTodayTexto(s, a, hoje: _hoje);
          expect(t.eyebrow, isNotEmpty, reason: '$mode ${s.localeName}');
          expect(t.titulo, isNotEmpty, reason: '$mode ${s.localeName}');
          expect(t.descricao, isNotEmpty, reason: '$mode ${s.localeName}');
          expect(t.cta, isNotEmpty, reason: '$mode ${s.localeName}');
        }
      }
    });

    test('treino pronto usa o nome e conta os exercícios', () {
      final t = alunoTodayTexto(_pt, _treino(), hoje: _hoje);
      expect(t.titulo, 'Treino A');
      expect(t.descricao, '6 exercícios no treino de hoje');
      expect(t.cta, 'Treinar agora');
    });

    test('retomada muda título e CTA', () {
      final pt = alunoTodayTexto(_pt, _treino(comeback: true), hoje: _hoje);
      expect(pt.titulo, 'Volte com Treino A');
      expect(pt.cta, 'Retomar agora');
      final en = alunoTodayTexto(_en, _treino(comeback: true), hoje: _hoje);
      expect(en.titulo, 'Come back with Treino A');
    });

    test('0 exercícios não diz "0 exercícios"', () {
      final t = alunoTodayTexto(_pt, _treino(exercicios: 0), hoje: _hoje);
      expect(t.descricao, isNot(contains('0')));
    });

    test('prazo entra na descrição do treino', () {
      final t = alunoTodayTexto(_pt, _treino(prazoFim: _hoje), hoje: _hoje);
      expect(t.descricao, '6 exercícios no treino de hoje · Vence hoje');
    });

    test('aguardando sem nome usa o título padrão', () {
      const a = AlunoTodayAction(
        mode: AlunoTodayMode.awaitingRelease,
        route: '/checkin/treinos',
      );
      expect(alunoTodayTexto(_pt, a).titulo, 'Treino em preparação');
    });
  });

  group('alunoPrazoTexto', () {
    test('sem prazo → null', () {
      expect(alunoPrazoTexto(_pt, null, hoje: _hoje), isNull);
    });

    test('atrasado, hoje e futuro', () {
      expect(
        alunoPrazoTexto(_pt, DateTime(2026, 9, 20), hoje: _hoje),
        contains('ainda dá para treinar'),
      );
      expect(alunoPrazoTexto(_pt, _hoje, hoje: _hoje), 'Vence hoje');
      expect(
        alunoPrazoTexto(_pt, DateTime(2026, 10, 1), hoje: _hoje),
        startsWith('Até '),
      );
      expect(
        alunoPrazoTexto(_en, DateTime(2026, 10, 1), hoje: _hoje),
        'Until Oct 1',
      );
    });
  });

  group('alunoPendenciaTexto', () {
    test('toda pendência tem título e detalhe', () {
      for (final tipo in AlunoPendenciaTipo.values) {
        final t = alunoPendenciaTexto(_pt, AlunoPendencia(tipo));
        expect(t.titulo, isNotEmpty);
        expect(t.detalhe, isNotEmpty);
      }
    });

    test('primeira medida tem texto próprio', () {
      final t = alunoPendenciaTexto(
        _pt,
        const AlunoPendencia(AlunoPendenciaTipo.medida, primeiraVez: true),
      );
      expect(t.titulo, 'Registrar primeira medida');
    });
  });

  group('semana', () {
    test('frase com meta, sequência e volume', () {
      const w = AlunoWeekSummary(
        feitos: 2,
        meta: 3,
        streakSemanas: 4,
        volumeKg: 3200,
      );
      expect(
        alunoWeekSemantics(_pt, w),
        '2 de 3 treinos nesta semana, sequência de 4 semanas, volume de 3.200 kg',
      );
      expect(alunoTreinosSemanaValor(_pt, w), '2 de 3');
    });

    test('sem meta e sem volume', () {
      const w = AlunoWeekSummary(
        feitos: 1,
        meta: null,
        streakSemanas: 0,
        volumeKg: null,
      );
      expect(
        alunoWeekSemantics(_pt, w),
        '1 treino nesta semana, sem sequência',
      );
      expect(alunoTreinosSemanaValor(_pt, w), '1');
    });

    test('sem dado de sessões começa pela sequência', () {
      const w = AlunoWeekSummary(
        feitos: null,
        meta: null,
        streakSemanas: 2,
        volumeKg: null,
      );
      expect(alunoWeekSemantics(_en, w), '2-week streak');
    });
  });

  test('números seguem o locale', () {
    expect(alunoForcaDeltaTexto(_pt, 4.2), '+4,2%');
    expect(alunoForcaDeltaTexto(_en, -1.5), '-1.5%');
    expect(alunoCargaTexto(_pt, 102.5), '102,5');
    expect(alunoCargaTexto(_pt, 100), '100');
  });

  test('alunoPrimeiroNome', () {
    expect(alunoPrimeiroNome('  Ana Paula Souza '), 'Ana');
    expect(alunoPrimeiroNome('Ana'), 'Ana');
  });
}
