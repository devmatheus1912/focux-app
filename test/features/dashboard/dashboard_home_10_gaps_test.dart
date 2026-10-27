import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/features/dashboard/utils/dashboard_day_focus.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_focus.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_microcopy.dart';

void main() {
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

