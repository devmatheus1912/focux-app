import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_day_focus.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_focus.dart';

void main() {
  group('DashboardHomeFocusRules', () {
    test('default focus on for retomada urgente', () {
      const focus = DashboardDayFocus(
        headline: 'Retomada urgente da base',
        detail: '8 de 8',
        semanticLabel: 'foco',
      );
      expect(
        DashboardHomeFocusRules.defaultFocusMode(
          dayFocus: focus,
          riskDominante: true,
        ),
        isTrue,
      );
    });

    test('focus mode collapses attention/finance and caps actions', () {
      const focus = DashboardDayFocus(
        headline: 'Retomada urgente da base',
        detail: 'x',
        semanticLabel: 'foco',
      );
      final rules = DashboardHomeFocusRules.resolve(
        focusMode: true,
        dayFocus: focus,
        riscoAlto: 8,
        receitaAtual: 0,
      );

      expect(rules.collapseAttention, isTrue);
      expect(rules.collapseFinance, isTrue);
      expect(rules.hidePromoBanners, isTrue);
      expect(rules.hideSecondaryRiskCtas, isTrue);
      expect(rules.collapseQuickLinks, isTrue);
      expect(rules.suppressSecondaryEmptyCtas, isTrue);
      expect(rules.compactCommandSticky, isTrue);
      expect(rules.maxVisibleNextActions, 2);
    });

    test('retention day hides promo even with focus off', () {
      const focus = DashboardDayFocus(
        headline: 'Retomada urgente da base',
        detail: 'x',
        semanticLabel: 'foco',
      );
      final rules = DashboardHomeFocusRules.resolve(
        focusMode: false,
        dayFocus: focus,
        riscoAlto: 8,
        receitaAtual: 0,
      );
      expect(rules.hidePromoBanners, isTrue);
      expect(rules.suppressSecondaryEmptyCtas, isTrue);
      expect(rules.compactCommandSticky, isFalse);
    });

    test('focus off keeps quick links available by default expanded', () {
      const focus = DashboardDayFocus(
        headline: 'Rotina estável',
        detail: 'x',
        semanticLabel: 'foco',
      );
      final rules = DashboardHomeFocusRules.resolve(
        focusMode: false,
        dayFocus: focus,
        riscoAlto: 0,
        receitaAtual: 1000,
      );
      expect(rules.collapseQuickLinks, isFalse);
      expect(rules.hidePromoBanners, isFalse);
      expect(rules.maxVisibleNextActions, 3);
    });
  });

  group('DashboardAderenciaCopy', () {
    test('does not echo foco do dia when retention focus', () {
      final body = DashboardAderenciaCopy.stoppedBody(retentionFocus: true);
      expect(body.toLowerCase().contains('foco do dia'), isFalse);
    });
  });
}
