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

    test('PRO — hábitos e financeiro, sem Enterprise', () {
      final f = _tier(SubscriptionPlan.PRO);
      expect(f.financeiro, isTrue);
      expect(f.habitCoaching, isTrue);
      expect(f.relatorios, isTrue);
      expect(f.automacoes, isFalse);
      expect(f.comunidadeGrupos, isFalse);
      expect(f.lojaDigital, isFalse);
      expect(f.landingCompleta, isFalse);
      expect(f.whiteLabel, isFalse);
    });

    test('ENTERPRISE — marca, loja, landing e equipe', () {
      final f = _tier(SubscriptionPlan.ENTERPRISE);
      expect(f.automacoes, isTrue);
      expect(f.equipeRbac, isTrue);
      expect(f.comunidadeGrupos, isTrue);
      expect(f.whiteLabel, isTrue);
      expect(f.lojaDigital, isTrue);
      expect(f.landingCompleta, isTrue);
      expect(f.poseCoach, isTrue);
      expect(f.automacoesAvancadas, isTrue);
      expect(f.limiteAssistentes, 5);
    });

    test('ENTERPRISE — tudo liberado mesmo com API deflacionada', () {
      const deflated = PlanoFeatures(
        plano: SubscriptionPlan.ENTERPRISE,
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
      expect(f.limiteAssistentes, 5);
    });
  });

  group('Dashboard shortcuts — atalhos trancados por tier', () {
    int locked(PlanoFeatures f) => DashboardToolShortcut.moreTools
        .where((s) => s.capability != null && !s.isUnlocked(f))
        .length;

    test('FREE tranca maioria dos atalhos pagos', () {
      expect(locked(_tier(SubscriptionPlan.FREE)), greaterThan(8));
    });

    test('PRO tranca Loja e Landing', () {
      final f = _tier(SubscriptionPlan.PRO);
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

    test('ENTERPRISE — zero atalhos trancados no grid', () {
      final f = _tier(SubscriptionPlan.ENTERPRISE);
      expect(locked(f), 0);
      for (final s in DashboardToolShortcut.moreTools) {
        if (s.capability != null) {
          expect(s.isUnlocked(f), isTrue, reason: s.label);
        }
      }
    });
  });
}
