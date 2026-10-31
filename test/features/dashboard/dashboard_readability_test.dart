import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_microcopy.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_readability.dart';

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


}
