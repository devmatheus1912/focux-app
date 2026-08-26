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
      expect(
        DashboardHomeFocusRules.defaultFocusMode(
          dayFocus: focus,
          riskDominante: true,
          persisted: false,
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
      );

      expect(rules.hidePromoBanners, isTrue);
      expect(rules.hideSecondaryRiskCtas, isTrue);
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
      );
      expect(rules.hidePromoBanners, isTrue);
      expect(rules.suppressSecondaryEmptyCtas, isTrue);
      // Toggle do usuário: Foco OFF revela secundário mesmo em retenção.
      expect(rules.compactCommandSticky, isFalse);
      expect(rules.omitSecondarySections, isFalse);
      expect(rules.hideFeaturedTools, isFalse);
      expect(rules.collapsePulseBody, isFalse);
      expect(rules.maxVisibleNextActions, 2);
    });

    test('focus off keeps secondary sections visible', () {
      const focus = DashboardDayFocus(
        headline: 'Rotina estável',
        detail: 'x',
        semanticLabel: 'foco',
      );
      final rules = DashboardHomeFocusRules.resolve(
        focusMode: false,
        dayFocus: focus,
      );
      expect(rules.hidePromoBanners, isFalse);
      expect(rules.hideFeaturedTools, isFalse);
      expect(rules.omitSecondarySections, isFalse);
      expect(rules.maxVisibleNextActions, 3);
    });

    test('calm day respects persisted focus off', () {
      const focus = DashboardDayFocus(
        headline: 'Rotina estável',
        detail: 'x',
        semanticLabel: 'foco',
      );
      expect(
        DashboardHomeFocusRules.defaultFocusMode(
          dayFocus: focus,
          riskDominante: false,
          persisted: false,
        ),
        isFalse,
      );
    });

    test('hides aderencia relatorio without ranking data', () {
      expect(
        dashboardShowAderenciaRelatorio(
          focusMode: false,
          coversRetention: false,
          weeklyCheckins: const [0, 0],
        ),
        isFalse,
      );
      expect(
        dashboardShowAderenciaRelatorio(
          focusMode: false,
          coversRetention: false,
          weeklyCheckins: const [2],
        ),
        isTrue,
      );
      expect(
        dashboardShowAderenciaRelatorio(
          focusMode: false,
          coversRetention: true,
          weeklyCheckins: const [4],
        ),
        isFalse,
      );
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
      expect(body.toLowerCase().contains('prioridade'), isFalse);
      expect(body.toLowerCase().contains('topo'), isFalse);
    });

    test('retention empty copy stays short', () {
      final empty = DashboardAderenciaCopy.emptyBody(retentionFocus: true);
      expect(empty.length, lessThan(48));
      expect(empty.toLowerCase().contains('topo'), isFalse);
    });
  });
}
