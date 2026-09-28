import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_texts.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_week.dart';
import 'package:focux_app/features/dashboard/utils/aluno_pendencias.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';
import 'package:focux_app/l10n/app_localizations.dart';

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
  setUpAll(() => GlobalMaterialLocalizations.delegate.load(const Locale('pt')));

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

    test('treino feito hoje não manda treinar de novo', () {
      AlunoTodayTexto feito(String? proximo) => alunoTodayTexto(
        _pt,
        AlunoTodayAction(
          mode: AlunoTodayMode.workoutDone,
          route: '/checkin/historico/50',
          treinoNome: 'Treino A',
          proximoTreinoNome: proximo,
        ),
      );
      final comProximo = feito('Treino B');
      expect(comProximo.eyebrow, 'Treino de hoje feito');
      expect(comProximo.titulo, 'Treino A');
      expect(comProximo.descricao, 'Próximo: Treino B');
      expect(comProximo.cta, 'Ver resumo');
      expect(feito(null).descricao, startsWith('Descanse'));
    });

    test('0 exercícios não diz "0 exercícios"', () {
      final t = alunoTodayTexto(_pt, _treino(exercicios: 0), hoje: _hoje);
      expect(t.descricao, isNot(contains('0')));
    });

    test('prazo tem linha própria', () {
      final t = alunoTodayTexto(_pt, _treino(prazoFim: _hoje), hoje: _hoje);
      expect(t.descricao, '6 exercícios no treino de hoje');
      expect(t.prazo, 'Vence hoje');
      expect(alunoTodayTexto(_pt, _treino(), hoje: _hoje).prazo, isNull);
    });

    test('prontidão baixa pede treino leve e mantém prazo e CTA', () {
      final t = alunoTodayTexto(
        _pt,
        _treino(prazoFim: _hoje),
        hoje: _hoje,
        prontidaoBaixa: true,
      );
      expect(
        t.descricao,
        'Corpo pedindo descanso: se treinar, vá leve ou faça mobilidade.',
      );
      expect(t.prazo, 'Vence hoje');
      expect(t.cta, 'Treinar agora');
    });

    test('horário no foco: hoje ou amanhã', () {
      final manha = DateTime(2026, 9, 27, 8);
      expect(
        alunoHorarioFocoTexto(_pt, DateTime(2026, 9, 27, 18), hoje: manha),
        'Horário com seu personal: hoje às 18:00',
      );
      expect(
        alunoHorarioFocoTexto(_pt, DateTime(2026, 9, 28, 7, 30), hoje: manha),
        'Horário com seu personal: amanhã às 07:30',
      );
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

    test('chat diz quantas mensagens', () {
      String detalhe(int n) =>
          alunoPendenciaTexto(
            _pt,
            AlunoPendencia(AlunoPendenciaTipo.chat, quantidade: n),
          ).detalhe;
      expect(detalhe(1), '1 mensagem nova');
      expect(detalhe(3), '3 mensagens novas');
    });

    test('agenda mostra quando é o próximo horário', () {
      final manha = DateTime(2026, 9, 27, 8);
      String quando(DateTime inicio) =>
          alunoPendenciaTexto(
            _pt,
            AlunoPendencia(AlunoPendenciaTipo.agenda, quando: inicio),
            hoje: manha,
          ).detalhe;
      expect(quando(DateTime(2026, 9, 27, 18)), 'Hoje às 18:00');
      expect(quando(DateTime(2026, 9, 28, 7, 30)), 'Amanhã às 07:30');
      expect(quando(DateTime(2026, 9, 30, 18)), endsWith('às 18:00'));
      expect(quando(DateTime(2026, 9, 30, 18)), contains('30'));
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

    test('meta superada: número, rótulo de meta e frase sem "6 de 2"', () {
      const w = AlunoWeekSummary(
        feitos: 6,
        meta: 2,
        streakSemanas: 1,
        volumeKg: 12445,
      );
      expect(alunoTreinosSemanaValor(_pt, w), '6');
      expect(alunoTreinosSemanaLabel(_pt, w), 'Meta 2 batida');
      expect(
        alunoWeekSemantics(_pt, w),
        '6 treinos nesta semana, meta de 2 batida, sequência de 1 semana, '
        'volume de 12.445 kg',
      );
    });

    test('meta igual: mesmo formato de meta batida', () {
      const w = AlunoWeekSummary(
        feitos: 3,
        meta: 3,
        streakSemanas: 2,
        volumeKg: null,
      );
      expect(alunoTreinosSemanaValor(_pt, w), '3');
      expect(alunoTreinosSemanaLabel(_pt, w), 'Meta 3 batida');
    });

    test('abaixo da meta: "2 de 3" e rótulo padrão', () {
      const w = AlunoWeekSummary(
        feitos: 2,
        meta: 3,
        streakSemanas: 0,
        volumeKg: null,
      );
      expect(alunoTreinosSemanaLabel(_pt, w), 'Treinos na semana');
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
    expect(alunoRecordeTexto(_pt, 'Supino', 102.5), 'Supino · 102,5 kg');
    expect(alunoRecordeTexto(_pt, 'Supino', 100), 'Supino · 100 kg');
    expect(alunoRecordeTexto(_pt, 'Supino', null), 'Supino');
    expect(alunoRecordeTexto(_pt, 'supino', 50), 'Supino · 50 kg');
    expect(alunoRecordeTexto(_pt, ' leg press 45°', null), 'Leg press 45°');
    expect(alunoRecordeTexto(_pt, 'Leg Press', 80), 'Leg Press · 80 kg');
    expect(alunoVolumeTexto(_en, 3200), '3,200 kg');
  });

  test('queda de força em tom de atenção', () {
    expect(alunoForcaDeltaTom(-1.5), EagleTokens.warn);
    expect(alunoForcaDeltaTom(-0.04), EagleTokens.good);
    expect(alunoForcaDeltaTom(0), EagleTokens.good);
    expect(alunoForcaDeltaTom(4.2), EagleTokens.good);
  });

  test('alunoPrimeiroNome', () {
    expect(alunoPrimeiroNome('  Ana Paula Souza '), 'Ana');
    expect(alunoPrimeiroNome('Ana'), 'Ana');
  });
}
