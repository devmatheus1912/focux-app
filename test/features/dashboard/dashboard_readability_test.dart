import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
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

  test('P1 badge uses solid good fill and dark ink in dark mode', () {
    final colors = dashboardPriorityBadgeColors(
      isDark: true,
      accent: EagleTokens.good,
      badge: 'P1',
    );
    expect(colors.background, EagleTokens.goodDark);
    expect(colors.foreground.computeLuminance() < 0.4, isTrue);
  });

  test('agenda empty with active base uses warn, never mute', () {
    expect(
      pulseAgendaAccent(
        agendaHoje: 0,
        alunosAtivos: 8,
        primary: EagleTokens.brand,
        caption: const Color(0xFFAABBCC),
        warn: EagleTokens.warn,
      ),
      EagleTokens.warn,
    );
    expect(
      pulseAgendaAccent(
        agendaHoje: 3,
        alunosAtivos: 8,
        primary: EagleTokens.brand,
        caption: const Color(0xFFAABBCC),
        warn: EagleTokens.warn,
      ),
      EagleTokens.brand,
    );
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
}
