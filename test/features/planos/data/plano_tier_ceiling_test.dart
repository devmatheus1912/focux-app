import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/dashboard_tool_shortcuts.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

PlanoFeatures _tier(SubscriptionPlan plan) => PlanoFeatures(
  plano: plan,
  financeiro: false,
  agenda: true,
  relatorios: false,
  whiteLabel: false,
  iaCopiloto: false,
  migracaoFoto: false,
).normalizeForTier();

void main() {
  group('normalizeForTier — matriz canônica', () {
    test('FREE só agenda básica', () {
      final f = _tier(SubscriptionPlan.FREE);
      expect(f.financeiro, isFalse);
      expect(f.habitCoaching, isFalse);
      expect(f.automacoes, isFalse);
      expect(f.lojaDigital, isFalse);
      expect(f.agenda, isTrue);
    });

    test('PREMIUM — hábitos e financeiro, sem Enterprise/Pro', () {
      final f = _tier(SubscriptionPlan.PREMIUM);
      expect(f.financeiro, isTrue);
      expect(f.habitCoaching, isTrue);
      expect(f.relatorios, isTrue);
      expect(f.automacoes, isFalse);
      expect(f.comunidadeGrupos, isFalse);
      expect(f.lojaDigital, isFalse);
      expect(f.landingCompleta, isFalse);
      expect(f.whiteLabel, isFalse);
    });

    test('ENTERPRISE — escala ops, sem Pro', () {
      final f = _tier(SubscriptionPlan.ENTERPRISE);
      expect(f.automacoes, isTrue);
      expect(f.equipeRbac, isTrue);
      expect(f.comunidadeGrupos, isTrue);
      expect(f.whiteLabel, isTrue);
      expect(f.lojaDigital, isFalse);
      expect(f.landingCompleta, isFalse);
      expect(f.poseCoach, isFalse);
      expect(f.automacoesAvancadas, isFalse);
      expect(f.limiteAssistentes, 1);
    });

    test('ENTERPRISE_PRO — tudo liberado mesmo com API deflacionada', () {
      const deflated = PlanoFeatures(
        plano: SubscriptionPlan.ENTERPRISE_PRO,
        financeiro: false,
        agenda: true,
        relatorios: false,
        whiteLabel: false,
        iaCopiloto: false,
        migracaoFoto: false,
        landingCompleta: false,
        lojaDigital: false,
        poseCoach: false,
        automacoes: false,
      );

      final f = deflated.normalizeForTier();

      expect(f.financeiro, isTrue);
      expect(f.landingCompleta, isTrue);
      expect(f.lojaDigital, isTrue);
      expect(f.poseCoach, isTrue);
      expect(f.automacoes, isTrue);
      expect(f.automacoesAvancadas, isTrue);
      expect(f.equipeRbac, isTrue);
      expect(f.limiteAssistentes, isNull);
    });

    test('ENTERPRISE bloqueia flags Pro mesmo com API inflada', () {
      const inflated = PlanoFeatures(
        plano: SubscriptionPlan.ENTERPRISE,
        financeiro: true,
        agenda: true,
        relatorios: true,
        whiteLabel: true,
        iaCopiloto: true,
        migracaoFoto: true,
        landingCompleta: true,
        habitCoaching: true,
        comunidadePrivada: true,
        automacoes: true,
        automacoesAvancadas: true,
        comunidadeGrupos: true,
        equipeRbac: true,
        lojaDigital: true,
        poseCoach: true,
        limiteAssistentes: 99,
      );

      final f = inflated.normalizeForTier();

      expect(f.landingCompleta, isFalse);
      expect(f.lojaDigital, isFalse);
      expect(f.poseCoach, isFalse);
      expect(f.automacoesAvancadas, isFalse);
      expect(f.automacoes, isTrue);
      expect(f.limiteAssistentes, 1);
    });
  });

  group('Dashboard shortcuts — atalhos trancados por tier', () {
    int locked(PlanoFeatures f) =>
        DashboardToolShortcut.moreTools
            .where((s) => s.capability != null && !s.isUnlocked(f))
            .length;

    test('FREE tranca maioria dos atalhos pagos', () {
      expect(locked(_tier(SubscriptionPlan.FREE)), greaterThan(8));
    });

    test('PREMIUM tranca Enterprise e Pro', () {
      final f = _tier(SubscriptionPlan.PREMIUM);
      expect(
        DashboardToolShortcut.moreTools
            .firstWhere((s) => s.label == 'Automações')
            .isUnlocked(f),
        isFalse,
      );
      expect(
        DashboardToolShortcut.moreTools
            .firstWhere((s) => s.label == 'Loja')
            .isUnlocked(f),
        isFalse,
      );
      expect(
        DashboardToolShortcut.moreTools
            .firstWhere((s) => s.label == 'Hábitos')
            .isUnlocked(f),
        isTrue,
      );
    });

    test('ENTERPRISE tranca só Pro (Loja + Landing)', () {
      final f = _tier(SubscriptionPlan.ENTERPRISE);
      expect(
        DashboardToolShortcut.moreTools
            .firstWhere((s) => s.label == 'Loja')
            .isUnlocked(f),
        isFalse,
      );
      expect(
        DashboardToolShortcut.moreTools
            .firstWhere((s) => s.label == 'Landing')
            .isUnlocked(f),
        isFalse,
      );
      expect(
        DashboardToolShortcut.moreTools
            .firstWhere((s) => s.label == 'Automações')
            .isUnlocked(f),
        isTrue,
      );
      expect(locked(f), 2);
    });

    test('ENTERPRISE_PRO — zero atalhos trancados no grid', () {
      final f = _tier(SubscriptionPlan.ENTERPRISE_PRO);
      expect(locked(f), 0);
      for (final s in DashboardToolShortcut.moreTools) {
        if (s.capability != null) {
          expect(s.isUnlocked(f), isTrue, reason: s.label);
        }
      }
    });
  });
}
