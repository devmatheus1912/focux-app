import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_anamnese.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_analytics.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_texts.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_view.dart';
import 'package:focux_app/features/dashboard/utils/aluno_pendencias.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';
import 'package:focux_app/features/health/data/health_repository.dart';
import 'package:focux_app/l10n/app_localizations.dart';

const _insight = {
  'tipo': 'PR',
  'confianca': 'HIGH',
  'titulo': 'Recorde novo',
  'mensagem': 'Supino subiu.',
  'acao': {'rota': '/checkin/historico', 'cta': 'Ver'},
};

AlunoDashboardHomeBundle _bundle({
  Object? anamnese,
  int coach = 0,
  bool inadimplente = false,
  Object? insight,
  String nomePersonal = '',
}) => AlunoDashboardHomeBundle.fromJson({
  'aluno': {
    'id': 7,
    'nome': 'Ana',
    'email': 'ana@focux.test',
    'status': 'ATIVO',
    'inadimplente': inadimplente,
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
  'insight': insight,
  'personalBrand': {'nomePersonal': nomePersonal},
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

    test('bloqueio financeiro não divide o card com insight', () {
      expect(
        buildAlunoHomeView(
          _bundle(inadimplente: true, insight: _insight),
          agendaReviewed: true,
        ).insight,
        isNull,
      );
      expect(
        buildAlunoHomeView(
          _bundle(insight: _insight),
          agendaReviewed: true,
        ).insight,
        isNotNull,
      );
    });

    test('sem treino a semana some', () {
      final view = buildAlunoHomeView(_bundle(), agendaReviewed: true);
      expect(view.semTreino, isTrue);
      expect(view.semanaVisivel, isFalse);
    });
  });

  group('atalhos', () {
    test('nenhum atalho repete destino que já está acima', () {
      final view = buildAlunoHomeView(
        _bundle(anamnese: 'SOLICITADA', insight: _insight),
        agendaReviewed: false,
        now: DateTime(2026, 9, 27),
      );
      expect(view.rotasNoTopo, contains('/aluno/anamnese'));
      expect(view.rotasNoTopo, contains('/checkin/historico'));
      expect(view.rotasNoTopo, contains('/aluno/perfil/editar'));
      for (final rota in view.atalhos) {
        expect(view.rotasNoTopo, isNot(contains(rota)));
      }
      expect(view.atalhos, hasLength(alunoAtalhosMax));
    });

    test('no bloqueio financeiro o financeiro sai dos atalhos', () {
      final view = buildAlunoHomeView(
        _bundle(inadimplente: true),
        agendaReviewed: true,
      );
      expect(view.action.route, '/financeiro/aluno');
      expect(view.atalhos, isNot(contains('/financeiro/aluno')));
    });

    test('chat no cabeçalho só com nome do personal', () {
      expect(
        buildAlunoHomeView(
          _bundle(nomePersonal: 'Leo'),
          agendaReviewed: true,
        ).rotasNoTopo,
        contains('/chat/aluno'),
      );
      expect(
        buildAlunoHomeView(_bundle(), agendaReviewed: true).chatNoCabecalho,
        isFalse,
      );
    });

    test('atalhos nunca apontam para abas do dock', () {
      const dock = [
        '/dashboard/aluno',
        '/checkin/treinos',
        '/saude',
        '/chat/aluno',
        '/aluno/perfil',
      ];
      for (final rota in alunoAtalhosPrioridade) {
        expect(dock, isNot(contains(rota)));
      }
    });
  });

  group('alunoProntidaoVisivel', () {
    const snap = RecoverySnapshot(
      steps: 0,
      caloriesBurned: 0,
      avgHeartRate: 0,
      sleepHours: 0,
      recoveryScore: 70,
      recoveryLabel: 'ok',
      recoveryHint: 'ok',
    );

    test('prontidão de hoje só com wearable', () {
      expect(
        alunoProntidaoVisivel(
          snapshot: snap,
          stale: false,
          hasWearableHistory: true,
        ),
        isTrue,
      );
      expect(
        alunoProntidaoVisivel(
          snapshot: snap,
          stale: false,
          hasWearableHistory: false,
        ),
        isFalse,
      );
    });

    test('sem prontidão de hoje: convite só quando a última é antiga', () {
      expect(
        alunoProntidaoVisivel(
          snapshot: null,
          stale: true,
          hasWearableHistory: true,
        ),
        isTrue,
      );
      expect(
        alunoProntidaoVisivel(
          snapshot: null,
          stale: false,
          hasWearableHistory: true,
        ),
        isFalse,
      );
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
