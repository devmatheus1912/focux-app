import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_microcopy.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_readability.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_screen_helpers.dart';

void main() {
  test('P0 badge uses solid warn fill and dark ink', () {
    final colors = dashboardPriorityBadgeColors(
      isDark: true,
      accent: EagleTokens.brand,
      badge: 'P0',
    );
    expect(colors.background, EagleTokens.warnDark);
    expect(colors.foreground.computeLuminance() < 0.35, isTrue);
  });

  test('P0 badge light uses deep warn and white ink', () {
    final colors = dashboardPriorityBadgeColors(
      isDark: false,
      accent: EagleTokens.brand,
      badge: 'P0',
    );
    expect(colors.background, EagleTokens.warnDeep);
    expect(colors.foreground, Colors.white);
    expect(colors.foreground.computeLuminance() > 0.8, isTrue);
  });

  test('P1 badge uses solid good fill and dark ink in dark mode', () {
    final colors = dashboardPriorityBadgeColors(
      isDark: true,
      accent: EagleTokens.good,
      badge: 'P1',
    );
    expect(colors.background, EagleTokens.goodDark);
    expect(colors.foreground.computeLuminance() < 0.4, isTrue);
  });

  test('pulse trend copy stays one line', () {
    expect(DashboardMicrocopy.tendencia7Dias, '7 dias');
    expect(DashboardMicrocopy.tendenciaVaziaBase, 'Sem treinos');
    expect(DashboardMicrocopy.tendencia7Dias.length, lessThanOrEqualTo(8));
    expect(DashboardMicrocopy.tendenciaVaziaBase.length, lessThanOrEqualTo(12));
  });

  test('pulse emptyHint prefers API then week-empty copy', () {
    expect(
      dashboardPulseEmptyHint(
        checkinsHoje: 0,
        checkinsTrend: const [0, 0, 0, 0, 0, 0, 0],
        fromApi: 'Sem treinos',
      ),
      'Sem treinos',
    );
    expect(
      dashboardPulseEmptyHint(
        checkinsHoje: 2,
        checkinsTrend: const [1, 0, 0, 0, 0, 0, 2],
      ),
      isNull,
    );
    expect(
      dashboardPulseEmptyHint(
        checkinsHoje: 0,
        checkinsTrend: const [1, 0, 0, 0, 0, 0, 0],
      ),
      'Nenhum check-in hoje',
    );
  });

  test('pulso: zero diz o que o zero significa', () {
    expect(pulseRiscoCopy(0).hint, 'Nenhum aluno em risco');
    expect(pulseRiscoCopy(0).semantics, 'Nenhum aluno em risco operacional');
    expect(pulseRiscoCopy(1).semantics, '1 aluno em risco operacional');
    expect(pulseRiscoCopy(3).hint, 'Alunos pedem contato');
    expect(pulseAtivosCopy(0).hint, 'Nenhum aluno ativo');
    expect(pulseAtivosCopy(4).hint, 'Base ativa');
    expect(pulseCheckinsCopy(0).hint, 'Sem movimento hoje');
    expect(pulseCheckinsCopy(2).hint, 'Check-ins de hoje');
  });
}
