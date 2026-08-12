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
      expect(rules.hideFeaturedTools, isTrue);
      expect(rules.omitSecondarySections, isTrue);
      expect(rules.collapsePulseBody, isTrue);
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

    test('focus off keeps quick links collapsed by default', () {
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
      expect(rules.collapseQuickLinks, isTrue);
      expect(rules.hidePromoBanners, isFalse);
      expect(rules.hideFeaturedTools, isFalse);
      expect(rules.omitSecondarySections, isFalse);
      expect(rules.maxVisibleNextActions, 3);
    });
  });

  group('DashboardHomeFocusRules.attentionVencLimit', () {
    test('zeroes vencimentos when focus is cobrança e retenção', () {
      const focus = DashboardDayFocus(
        headline: 'Cobrança e retenção hoje',
        detail: 'x',
        semanticLabel: 'foco',
      );
      expect(
        DashboardHomeFocusRules.attentionVencLimit(
          dayFocus: focus,
          dayFocusCoversRetention: true,
          focusMode: true,
        ),
        0,
      );
    });

    test('keeps vencimentos when focus is only risk retomada', () {
      const focus = DashboardDayFocus(
        headline: 'Retomada urgente da base',
        detail: 'x',
        semanticLabel: 'foco',
      );
      expect(
        DashboardHomeFocusRules.attentionVencLimit(
          dayFocus: focus,
          dayFocusCoversRetention: true,
          focusMode: false,
        ),
        2,
      );
    });
  });

  group('DashboardHomeFocusRules.attentionRiskLimit', () {
    test('zeroes risk cards when day focus already owns retention', () {
      expect(
        DashboardHomeFocusRules.attentionRiskLimit(
          dayFocusCoversRetention: true,
          focusMode: false,
          riskDominante: true,
        ),
        0,
      );
      expect(
        DashboardHomeFocusRules.attentionRiskLimit(
          dayFocusCoversRetention: true,
          focusMode: true,
          riskDominante: false,
        ),
        0,
      );
    });

    test('respects focus mode and risk dominance when not covered', () {
      expect(
        DashboardHomeFocusRules.attentionRiskLimit(
          dayFocusCoversRetention: false,
          focusMode: true,
          riskDominante: false,
        ),
        1,
      );
      expect(
        DashboardHomeFocusRules.attentionRiskLimit(
          dayFocusCoversRetention: false,
          focusMode: false,
          riskDominante: true,
        ),
        2,
      );
      expect(
        DashboardHomeFocusRules.attentionRiskLimit(
          dayFocusCoversRetention: false,
          focusMode: false,
          riskDominante: false,
        ),
        4,
      );
    });
  });

  group('DashboardAderenciaCopy', () {
    test('does not echo foco do dia when retention focus', () {
      final body = DashboardAderenciaCopy.stoppedBody(retentionFocus: true);
      expect(body.toLowerCase().contains('foco do dia'), isFalse);
    });
  });
}
