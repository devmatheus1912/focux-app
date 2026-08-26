import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_day_focus.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_focus.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_microcopy.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_radar_items.dart';

void main() {
  group('dashboardRadarItems', () {
    test('limits and preserves order', () {
      final scores = List.generate(
        5,
        (i) => AlunoScoreResumo(
          alunoId: i,
          alunoNome: 'A$i',
          score: 90 - i,
          ritmo: 'ok',
          risco: 'baixo',
          proximaAcao: 'Abrir',
          narrativa: '',
          objetivo: '',
          acaoUrl: '/alunos/$i',
          prioridade: 'P1',
          iaSugerida: false,
        ),
      );
      final top = dashboardRadarItems(scores, limit: 3);
      expect(top, hasLength(3));
      expect(top.first.alunoId, 0);
      expect(top.last.alunoId, 2);
    });

    test('radar icon is triangle only on high risk', () {
      expect(dashboardRadarIcon('Risco alto'), 'alert-triangle');
      expect(dashboardRadarIcon('Risco médio'), 'trend');
      expect(dashboardRadarIcon('Risco baixo'), 'target');
    });

    test('radar caption is PT-BR and countable', () {
      expect(dashboardRadarCaption(1), contains('1 aluno'));
      expect(dashboardRadarCaption(3), contains('3 alunos'));
    });

    test('radar strip is inset group, not accordion', () {
      final src =
          File(
            'lib/features/dashboard/widgets/dashboard_base_radar_strip.dart',
          ).readAsStringSync();
      expect(src, contains('FxSettingsGroup'));
      expect(src, contains('FxSettingsTile'));
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
