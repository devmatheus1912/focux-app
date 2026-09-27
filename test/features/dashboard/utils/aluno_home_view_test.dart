import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_anamnese.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_analytics.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_texts.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_view.dart';
import 'package:focux_app/features/dashboard/utils/aluno_pendencias.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';
import 'package:focux_app/l10n/app_localizations.dart';

AlunoDashboardHomeBundle _bundle({Object? anamnese, int coach = 0}) =>
    AlunoDashboardHomeBundle.fromJson({
      'aluno': {
        'id': 7,
        'nome': 'Ana',
        'email': 'ana@focux.test',
        'status': 'ATIVO',
      },
      'treinos': [],
      'historicoResumo': [],
      'medidas': [],
      'chat': {'naoLidasDoPersonal': 2},
      'coachMensagens': [
        for (var i = 0; i < coach; i++)
          {'id': i, 'mensagem': 'oi', 'tipo': 'MOTIVACAO'},
      ],
      'anamnesePendente': anamnese,
    });

void main() {
  group('AlunoAnamnesePendente', () {
    test('só os status que pedem ação', () {
      expect(
        AlunoAnamnesePendente.tryParse('SOLICITADA'),
        AlunoAnamnesePendente.solicitada,
      );
      expect(
        AlunoAnamnesePendente.tryParse('PRECISA_ATESTADO'),
        AlunoAnamnesePendente.precisaAtestado,
      );
      expect(AlunoAnamnesePendente.tryParse('PREENCHIDA'), isNull);
      expect(AlunoAnamnesePendente.tryParse(null), isNull);
    });

    test('bundle lê o campo do BFF', () {
      expect(
        _bundle(anamnese: 'SOLICITADA').anamnesePendente,
        AlunoAnamnesePendente.solicitada,
      );
      expect(_bundle().anamnesePendente, isNull);
    });

    test('texto do aviso por status', () {
      final s = lookupS(const Locale('pt'));
      expect(
        alunoAnamneseAvisoTexto(s, AlunoAnamnesePendente.solicitada).titulo,
        'Anamnese solicitada',
      );
      expect(
        alunoAnamneseAvisoTexto(s, AlunoAnamnesePendente.precisaAtestado)
            .titulo,
        'Seu personal pediu atestado',
      );
    });
  });

  group('buildAlunoHomeView', () {
    test('anamnese pendente vira o aviso da Home', () {
      final view = buildAlunoHomeView(
        _bundle(anamnese: 'SOLICITADA'),
        agendaReviewed: false,
      );
      expect(view.aviso, AlunoHomeAviso.anamnese);
      expect(view.semTreino, isTrue);
    });

    test('Home mostra 3; abertas guardam todas', () {
      final view = buildAlunoHomeView(
        _bundle(),
        agendaReviewed: false,
        now: DateTime(2026, 9, 27),
      );
      expect(view.pendenciasAbertas.length, greaterThan(alunoPendenciasMax));
      expect(view.pendencias, hasLength(alunoPendenciasMax));
      expect(view.aviso, AlunoHomeAviso.nenhum);
    });
  });

  group('AlunoHomeAnalytics', () {
    const acao = AlunoTodayAction(
      mode: AlunoTodayMode.workoutReady,
      route: '/checkin',
      comeback: true,
    );

    test('viewed leva modo, retomada, pendências e aviso', () {
      expect(
        AlunoHomeAnalytics.viewedProps(
          action: acao,
          pendencias: 2,
          aviso: AlunoHomeAviso.coach,
        ),
        {
          'mode': 'workoutReady',
          'comeback': true,
          'pendencias': 2,
          'aviso': 'coach',
        },
      );
    });

    test('focus action leva a rota do P0', () {
      expect(AlunoHomeAnalytics.focusActionProps(acao), {
        'mode': 'workoutReady',
        'comeback': true,
        'route': '/checkin',
      });
    });
  });
}
