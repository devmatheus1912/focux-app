import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_day_focus.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_focus.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_microcopy.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_radar_items.dart';

void main() {
  group('dashboardRadarSplit', () {
    test('limits and preserves order', () {
      final scores = List.generate(
        5,
        (i) => _score(id: i, nome: 'A$i', acao: 'Retomar treino com mensagem curta'),
      );
      final split = dashboardRadarSplit(scores);
      expect(split.fold, hasLength(dashboardRadarFoldLimit));
      expect(split.fold.first.alunoId, 0);
      expect(split.more.last.alunoId, 4);
    });

    test('radar icon is triangle only on high risk', () {
      expect(dashboardRadarIcon('Risco alto'), 'alert-triangle');
      expect(dashboardRadarIcon('Risco médio'), 'trend');
      expect(dashboardRadarIcon('Risco moderado'), 'trend');
      expect(dashboardRadarIcon('Risco baixo'), 'target');
    });

    test('radar caption is PT-BR and countable', () {
      expect(
        dashboardRadarCaption(fold: 1, total: 1),
        contains('Contato hoje'),
      );
      expect(
        dashboardRadarCaption(fold: 2, total: 2),
        contains('2 pedem contato'),
      );
      expect(
        dashboardRadarCaption(fold: 2, total: 4),
        contains('2 no Hoje'),
      );
    });

    test('cadastro and ficha gaps stay off the Hoje fold', () {
      expect(
        dashboardRadarBelongsOnHome(
          _score(
            acao: 'Completar mapa corporal',
            risco: 'Risco alto',
            prioridade: 'P0',
          ),
        ),
        isFalse,
      );
      expect(
        dashboardRadarBelongsOnHome(
          _score(
            acao: 'Pedir feedback objetivo',
            risco: 'Risco baixo',
            prioridade: 'P1',
          ),
        ),
        isFalse,
      );
      expect(
        dashboardRadarBelongsOnHome(
          _score(
            acao: 'Retomar treino com mensagem curta',
            risco: 'Risco alto',
            prioridade: 'P0',
          ),
        ),
        isTrue,
      );
      expect(
        dashboardRadarBelongsOnHome(
          _score(
            acao: 'Regularizar financeiro',
            risco: 'Risco baixo',
            prioridade: 'P0',
          ),
        ),
        isTrue,
      );
    });

    test('fold keeps 2 operational students; overflow goes to sheet', () {
      final scores = [
        _score(id: 1, nome: 'Ana', acao: 'Completar mapa corporal'),
        _score(
          id: 2,
          nome: 'Bruno',
          acao: 'Retomar treino com mensagem curta',
        ),
        _score(
          id: 3,
          nome: 'Carla',
          acao: 'Retomar treino com mensagem curta',
        ),
        _score(id: 4, nome: 'Diego', acao: 'Regularizar financeiro'),
        _score(
          id: 5,
          nome: 'Eva',
          acao: 'Pedir feedback objetivo',
          risco: 'Risco baixo',
          prioridade: 'P1',
        ),
      ];
      final split = dashboardRadarSplit(scores);
      expect(split.fold.map((e) => e.alunoNome), ['Bruno', 'Carla']);
      expect(split.more.map((e) => e.alunoNome), ['Diego']);
      expect(dashboardRadarVisibleOnHome(scores), isTrue);
      expect(
        dashboardRadarVisibleOnHome([
          _score(acao: 'Completar mapa corporal'),
        ]),
        isFalse,
      );
    });

    test('radar strip is inset group, not accordion', () {
      final src =
          File(
            'lib/features/dashboard/widgets/dashboard_base_radar_strip.dart',
          ).readAsStringSync();
      expect(src, contains('FxSettingsGroup'));
      expect(src, contains('DashboardRadarTile'));
      expect(src, contains('radarVerTodos'));
      expect(src, isNot(contains('DashboardCollapsibleSection')));
      expect(src, isNot(contains('DashboardHorizontalScrollPeek')));
    });
  });

  group('DashboardDayFocus.fromJson', () {
    test('parses BFF kind and coversRetention', () {
      final focus = DashboardDayFocus.fromJson({
        'kind': 'RETOMADA_URGENTE',
        'headline': 'Retomada urgente da base',
        'detail': '4 de 8',
        'semanticLabel': 'Foco',
        'coversRetention': true,
        'riskDominante': true,
      });
      expect(focus.kind, DashboardDayFocusKind.retomadaUrgente);
      expect(DashboardHomeFocusRules.coversRetention(focus), isTrue);
    });
  });

  group('DashboardMicrocopy.atualizadoHa', () {
    test('formats age bands', () {
      expect(
        DashboardMicrocopy.atualizadoHa(const Duration(seconds: 5)),
        'Atualizado agora',
      );
      expect(
        DashboardMicrocopy.atualizadoHa(const Duration(seconds: 40)),
        'Atualizado há 40s',
      );
      expect(
        DashboardMicrocopy.atualizadoHa(const Duration(minutes: 3)),
        'Atualizado há 3min',
      );
    });
  });
}

AlunoScoreResumo _score({
  int id = 1,
  String nome = 'Ana',
  String risco = 'Risco alto',
  String acao = 'Retomar treino com mensagem curta',
  String prioridade = 'P0',
}) {
  return AlunoScoreResumo(
    alunoId: id,
    alunoNome: nome,
    score: 70,
    ritmo: 'ok',
    risco: risco,
    proximaAcao: acao,
    narrativa: '',
    objetivo: '',
    acaoUrl: '/alunos/$id',
    prioridade: prioridade,
    iaSugerida: false,
  );
}
