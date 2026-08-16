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

  test('agenda empty stays caption so check-ins keep the only warn', () {
    const caption = Color(0xFFAABBCC);
    expect(
      pulseAgendaAccent(
        agendaHoje: 0,
        primary: EagleTokens.brand,
        caption: caption,
      ),
      caption,
    );
    expect(
      pulseAgendaAccent(
        agendaHoje: 3,
        primary: EagleTokens.brand,
        caption: caption,
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
