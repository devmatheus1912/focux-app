import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_texts.dart';
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
      expect(t.cta, 'Começar');
      expect(t.eyebrow, 'Agora');
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
      expect(comProximo.eyebrow, 'Pronto por hoje');
      expect(comProximo.titulo, 'Treino A');
      expect(comProximo.descricao, 'Quando quiser: Treino B');
      expect(comProximo.cta, 'Fazer mais um');
      expect(comProximo.ctaPrimario, isFalse);
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
      expect(t.cta, 'Começar');
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
  });

  test('números seguem o locale', () {
    expect(alunoForcaDeltaTexto(_pt, 4.2), '+4,2%');
    expect(alunoForcaDeltaTexto(_en, -1.5), '-1.5%');
    expect(alunoVolumeTexto(_en, 3200), '3,200 kg');
  });

  test('alunoPrimeiroNome', () {
    expect(alunoPrimeiroNome('  Ana Paula Souza '), 'Ana');
    expect(alunoPrimeiroNome('Ana'), 'Ana');
  });
}
