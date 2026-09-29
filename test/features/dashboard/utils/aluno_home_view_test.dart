import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/coach/data/coach_proativo_repository.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_anamnese.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_insight.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_analytics.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_texts.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_view.dart';
import 'package:focux_app/features/dashboard/utils/aluno_pendencias.dart';
import 'package:focux_app/features/dashboard/utils/aluno_today_action.dart';
import 'package:focux_app/features/health/data/health_repository.dart';
import 'package:focux_app/l10n/app_localizations.dart';

const _insight = {
  'tipo': 'RITMO_CAIU',
  'confianca': 'HIGH',
  'titulo': 'Seu ritmo caiu',
  'mensagem':
      'Nas 4 semanas anteriores, sua média era de 3 treinos por semana.',
};

AlunoDashboardHomeBundle _bundle({
  Object? anamnese,
  int coach = 0,
  bool inadimplente = false,
  Object? insight,
  String nomePersonal = '',
  List<String> recursosIndisponiveis = const [],
  String? recordeEm,
  int ofertas = 0,
  int fichas = 0,
  String? concluidoEm,
  int? concluidosSemana,
  String? agendaInicio,
}) => AlunoDashboardHomeBundle.fromJson({
  'aluno': {
    'id': 7,
    'nome': 'Ana',
    'email': 'ana@focux.test',
    'status': 'ATIVO',
    'inadimplente': inadimplente,
  },
  'treinos': [
    for (var i = 0; i < fichas; i++)
      {'treinoId': 10 + i, 'treinoNome': 'Treino $i', 'status': 'DISPONIVEL'},
  ],
  'historicoResumo': [
    if (concluidoEm != null)
      {
        'id': 50,
        'treinoId': 10,
        'treinoNome': 'Treino 0',
        'status': 'CONCLUIDO',
        'concluidoEm': concluidoEm,
      },
  ],
  'concluidosSemanaIso': concluidosSemana,
  'agendaProximoInicio': agendaInicio,
  'upsellPendentes': [
    for (var i = 0; i < ofertas; i++)
      {'alunoOfertaId': i, 'ofertaId': i, 'titulo': 'Extra', 'valor': 150},
  ],
  'medidas': [],
  'chat': {'naoLidasDoPersonal': 2},
  'coachMensagens': [
    for (var i = 0; i < coach; i++)
      {'id': i, 'mensagem': 'oi', 'tipo': 'MOTIVACAO'},
  ],
  'anamnesePendente': anamnese,
  'insight': insight,
  'personalBrand': {'nomePersonal': nomePersonal},
  'recursosIndisponiveis': recursosIndisponiveis,
  'recordes': [
    if (recordeEm != null)
      {'id': 1, 'exercicioId': 2, 'exercicioNome': 'Supino', 'data': recordeEm},
  ],
});

CoachMensagem _coach(String tipo) => CoachMensagem(
  id: tipo.hashCode,
  tipo: tipo,
  mensagem: 'oi',
  criadoEm: '2026-09-27T08:00:00',
  lido: false,
);

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
        alunoAnamneseAvisoTexto(
          s,
          AlunoAnamnesePendente.precisaAtestado,
        ).titulo,
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
      expect(view.jaTreinou, isFalse);
    });

    test('Home mostra 3; abertas guardam todas', () {
      final view = buildAlunoHomeView(
        _bundle(fichas: 1, agendaInicio: '2026-09-30T18:00:00'),
        agendaReviewed: false,
        now: DateTime(2026, 9, 27),
      );
      expect(view.pendenciasAbertas.length, greaterThan(alunoPendenciasMax));
      expect(view.pendencias, hasLength(alunoPendenciasMax));
      expect(view.aviso, AlunoHomeAviso.nenhum);
    });

    test('mensalidade atrasada vira aviso e o foco segue no treino', () {
      final view = buildAlunoHomeView(
        _bundle(
          inadimplente: true,
          fichas: 1,
          insight: _insight,
          anamnese: 'SOLICITADA',
        ),
        agendaReviewed: true,
      );
      expect(view.action.mode, AlunoTodayMode.workoutReady);
      expect(view.aviso, AlunoHomeAviso.financeiro);
      expect(view.financeiroEmAtraso, isTrue);
      expect(view.insight, isNotNull);
    });

    test('quem acabou de treinar não lê "Seu ritmo caiu"', () {
      final ritmo = AlunoHomeInsight.tryParse(_insight)!;
      final volume =
          AlunoHomeInsight.tryParse({..._insight, 'tipo': 'VOLUME_SUBINDO'})!;
      expect(alunoInsightNoFoco(ritmo, AlunoTodayMode.workoutDone), isNull);
      expect(alunoInsightNoFoco(volume, AlunoTodayMode.workoutDone), volume);
      expect(alunoInsightNoFoco(ritmo, AlunoTodayMode.workoutReady), ritmo);

      final view = buildAlunoHomeView(
        _bundle(
          fichas: 2,
          concluidoEm: '2026-09-27T07:30:00',
          insight: _insight,
        ),
        agendaReviewed: true,
        now: DateTime(2026, 9, 27, 18),
      );
      expect(view.action.mode, AlunoTodayMode.workoutDone);
      expect(view.insight, isNull);
    });

    test('mensalidade atrasada não oferece compra', () {
      expect(
        buildAlunoHomeView(
          _bundle(inadimplente: true, ofertas: 1),
          agendaReviewed: true,
        ).ofertas,
        isEmpty,
      );
      expect(
        buildAlunoHomeView(_bundle(ofertas: 1), agendaReviewed: true).ofertas,
        hasLength(1),
      );
    });

    test('ficha sem treino concluído: semana e evolução ficam fora', () {
      final view = buildAlunoHomeView(
        _bundle(fichas: 1, concluidosSemana: 0),
        agendaReviewed: true,
      );
      expect(view.jaTreinou, isFalse);
      expect(view.semanaVisivel, isFalse);
    });

    test('depois do primeiro treino a semana aparece', () {
      final view = buildAlunoHomeView(
        _bundle(
          fichas: 1,
          concluidoEm: '2026-09-25T10:00:00',
          concluidosSemana: 1,
        ),
        agendaReviewed: true,
        now: DateTime(2026, 9, 27),
      );
      expect(view.jaTreinou, isTrue);
      expect(view.semanaVisivel, isTrue);
    });

    test('agenda só entra com horário e leva quando é', () {
      AlunoPendencia? agenda(String? inicio) =>
          buildAlunoHomeView(
                _bundle(agendaInicio: inicio),
                agendaReviewed: false,
                now: DateTime(2026, 9, 27),
              ).pendenciasAbertas
              .where((p) => p.tipo == AlunoPendenciaTipo.agenda)
              .firstOrNull;
      expect(agenda(null), isNull);
      expect(agenda('2026-09-30T18:00:00')?.quando, DateTime(2026, 9, 30, 18));
    });

    test('horário no foco só hoje ou amanhã', () {
      final agora = DateTime(2026, 9, 27, 8);
      expect(alunoHorarioNoFoco(DateTime(2026, 9, 27, 18), agora), isNotNull);
      expect(alunoHorarioNoFoco(DateTime(2026, 9, 28, 7), agora), isNotNull);
      expect(alunoHorarioNoFoco(DateTime(2026, 9, 29, 7), agora), isNull);
      expect(alunoHorarioNoFoco(DateTime(2026, 9, 26, 7), agora), isNull);
      expect(alunoHorarioNoFoco(DateTime(2026, 9, 27, 7), agora), isNull);
      expect(alunoHorarioNoFoco(agora, agora), isNull);
      expect(alunoHorarioNoFoco(null, agora), isNull);
      final view = buildAlunoHomeView(
        _bundle(agendaInicio: '2026-09-27T18:00:00'),
        agendaReviewed: false,
        now: agora,
      );
      expect(view.horarioNoFoco, DateTime(2026, 9, 27, 18));
      expect(
        view.pendenciasAbertas.map((p) => p.tipo),
        isNot(contains(AlunoPendenciaTipo.agenda)),
      );
    });

    test('view vale até o horário do foco ou a meia-noite', () {
      final agora = DateTime(2026, 9, 27, 8);
      final meiaNoite = DateTime(2026, 9, 28);
      DateTime validaAte(String? inicio) => alunoHomeViewValidaAte(
        buildAlunoHomeView(
          _bundle(agendaInicio: inicio),
          agendaReviewed: true,
          now: agora,
        ),
        agora,
      );
      expect(validaAte('2026-09-27T18:00:00'), DateTime(2026, 9, 27, 18));
      expect(validaAte('2026-09-28T07:00:00'), meiaNoite);
      expect(validaAte('2026-09-27T07:00:00'), meiaNoite);
      expect(validaAte(null), meiaNoite);
    });

    test('mesmo bundle no dia seguinte: feito hoje vira treino pronto', () {
      final home = _bundle(fichas: 2, concluidoEm: '2026-09-27T07:30:00');
      AlunoTodayMode modo(DateTime now) =>
          buildAlunoHomeView(home, agendaReviewed: true, now: now).action.mode;
      expect(modo(DateTime(2026, 9, 27, 20)), AlunoTodayMode.workoutDone);
      expect(modo(DateTime(2026, 9, 28, 7)), AlunoTodayMode.workoutReady);
    });

    test('atestado pedido vem antes da mensalidade', () {
      final view = buildAlunoHomeView(
        _bundle(anamnese: 'PRECISA_ATESTADO', inadimplente: true),
        agendaReviewed: true,
      );
      expect(view.aviso, AlunoHomeAviso.atestado);
      expect(view.financeiroEmAtraso, isTrue);
      expect(view.ofertas, isEmpty);
      expect(view.rotasNoTopo, contains('/aluno/anamnese'));
      expect(view.atalhos, isNot(contains('/aluno/anamnese')));
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
      expect(view.rotasNoTopo, contains('/aluno/perfil/editar'));
      for (final rota in view.atalhos) {
        expect(view.rotasNoTopo, isNot(contains(rota)));
      }
      expect(view.atalhos, hasLength(alunoAtalhosMax));
    });

    test('com mensalidade atrasada o financeiro sai dos atalhos', () {
      final view = buildAlunoHomeView(
        _bundle(inadimplente: true),
        agendaReviewed: true,
      );
      expect(view.action.route, isNot(alunoFinanceiroRoute));
      expect(view.rotasNoTopo, contains(alunoFinanceiroRoute));
      expect(view.atalhos, isNot(contains(alunoFinanceiroRoute)));
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

    test('ferramenta sem recurso no plano do personal sai dos atalhos', () {
      final view = buildAlunoHomeView(
        _bundle(recursosIndisponiveis: ['HABIT_COACHING', 'COMUNIDADE_GRUPOS']),
        agendaReviewed: true,
        now: DateTime(2026, 9, 27),
      );
      expect(view.atalhos, isNot(contains('/aluno/habitos')));
      expect(view.atalhos, isNot(contains('/aluno/desafios')));
      expect(alunoFerramentaLiberada('/aluno/habitos', const {}), isTrue);
      expect(
        alunoFerramentaLiberada('/agenda/aluno', {'HABIT_COACHING'}),
        isTrue,
      );
    });

    test('plano sem agenda tira o atalho de agenda', () {
      final view = buildAlunoHomeView(
        _bundle(recursosIndisponiveis: ['AGENDA']),
        agendaReviewed: true,
        now: DateTime(2026, 9, 27),
      );
      expect(view.atalhos, isNot(contains('/agenda/aluno')));
      expect(alunoFerramentaLiberada('/agenda/aluno', {'AGENDA'}), isFalse);
    });

    test('anamnese por último: não é tarefa do dia', () {
      expect(alunoAtalhosPrioridade.last, '/aluno/anamnese');
      expect(alunoAtalhosPrioridade.take(3), [
        '/agenda/aluno',
        '/checkin/historico',
        '/aluno/habitos',
      ]);
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

  group('alunoCoachVisiveis', () {
    final todas = [
      _coach('SEM_TREINO_5D'),
      _coach('STREAK_QUEBRADO'),
      _coach('SONO_BAIXO'),
    ];

    test('retomada no card Hoje tira dias sem treino e sequência parada', () {
      final tipos = alunoCoachVisiveis(
        todas,
        comeback: true,
        prontidaoVisivel: false,
      ).map((m) => m.tipo);
      expect(tipos, ['SONO_BAIXO']);
    });

    test('prontidão visível tira sono curto', () {
      final tipos = alunoCoachVisiveis(
        todas,
        comeback: false,
        prontidaoVisivel: true,
      ).map((m) => m.tipo);
      expect(tipos, ['SEM_TREINO_5D', 'STREAK_QUEBRADO']);
    });

    test('aviso de coach conta só as visíveis', () {
      final view = buildAlunoHomeView(_bundle(coach: 2), agendaReviewed: true);
      expect(view.coach, hasLength(2));
      expect(view.aviso, AlunoHomeAviso.coach);
    });
  });

  group('alunoRecordeRecente', () {
    final hoje = DateTime(2026, 9, 27, 15);

    test('até 7 dias é novo; depois ou data ruim não', () {
      expect(alunoRecordeRecente('2026-09-27', hoje), isTrue);
      expect(alunoRecordeRecente('2026-09-20', hoje), isTrue);
      expect(alunoRecordeRecente('2026-09-19', hoje), isFalse);
      expect(alunoRecordeRecente('2026-09-28', hoje), isFalse);
      expect(alunoRecordeRecente('x', hoje), isFalse);
      expect(alunoRecordeRecente(null, hoje), isFalse);
    });

    test('view marca o recorde recente', () {
      expect(
        buildAlunoHomeView(
          _bundle(recordeEm: '2026-09-25'),
          agendaReviewed: true,
          now: hoje,
        ).recordeRecente,
        isTrue,
      );
      expect(
        buildAlunoHomeView(
          _bundle(),
          agendaReviewed: true,
          now: hoje,
        ).recordeRecente,
        isFalse,
      );
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

    test('prontidão baixa só com treino pronto e prontidão na tela', () {
      const baixa = RecoverySnapshot(
        steps: 0,
        caloriesBurned: 0,
        avgHeartRate: 0,
        sleepHours: 0,
        recoveryScore: 40,
        recoveryLabel: 'baixa',
        recoveryHint: 'leve',
      );
      bool b({
        AlunoTodayMode mode = AlunoTodayMode.workoutReady,
        RecoverySnapshot? s = baixa,
        bool visivel = true,
      }) => alunoProntidaoBaixa(
        mode: mode,
        snapshot: s,
        prontidaoVisivel: visivel,
      );
      expect(b(), isTrue);
      expect(b(s: snap), isFalse);
      expect(b(visivel: false), isFalse);
      expect(b(mode: AlunoTodayMode.workoutDone), isFalse);
      expect(b(s: null), isFalse);
      expect(
        b(s: RecoverySnapshot.fromJson({'recoveryLabel': 'baixa'})),
        isFalse,
        reason: 'nota ausente não é prontidão baixa',
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
