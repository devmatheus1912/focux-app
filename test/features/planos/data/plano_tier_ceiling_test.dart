import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/dashboard_tool_shortcuts.dart';
import 'package:focux_app/features/ferramentas/data/ferramentas_catalogo_models.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

import '../../ferramentas/catalogo_fixture.dart';

PlanoFeatures _tier(SubscriptionPlan plan) => PlanoFeatures(
  plano: plan,
  financeiro: false,
  agenda: true,
  relatorios: false,
  whiteLabel: false,
  iaCopiloto: false,
  migracaoFoto: false,
).normalizeForTier();

List<DashboardToolShortcut> _leaves() {
  final catalogo = FerramentasCatalogo.fromJson(catalogoFixtureJson());
  return [for (final hub in catalogo.hubs) ...catalogLeavesFromHub(hub)];
}

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
    int locked(PlanoFeatures f) =>
        _leaves().where((s) => s.capability != null && !s.isUnlocked(f)).length;

    test('FREE tranca maioria dos atalhos pagos', () {
      expect(locked(_tier(SubscriptionPlan.FREE)), greaterThan(0));
    });

    test('PRO tranca Loja no hub de vendas', () {
      final f = _tier(SubscriptionPlan.PRO);
      final leaves = _leaves();
      final lojaHub = leaves.firstWhere((s) => s.label == 'Vendas');
      expect(lojaHub.entrada.abas.any((a) => a.id == 'loja'), isTrue);
      final lojaAba = DashboardToolShortcut.fromEntrada(
        lojaHub.entrada.abas.firstWhere((a) => a.id == 'loja'),
      );
      expect(lojaAba.isUnlocked(f), isFalse);
    });

    test('ENTERPRISE — capabilities locais liberam folhas com gate', () {
      final f = _tier(SubscriptionPlan.ENTERPRISE);
      for (final s in _leaves()) {
        if (s.capability == null) continue;
        // unlocked do BFF fixture pode ser false; capability local ENTERPRISE ok
        // quando forçamos unlocked via cópia:
        final forced = DashboardToolShortcut.fromEntrada(
          CatalogoEntrada(
            id: s.entrada.id,
            titulo: s.entrada.titulo,
            rotaApp: s.entrada.rotaApp,
            featureGate: s.entrada.featureGate,
            unlocked: true,
            upgradePlano: s.entrada.upgradePlano,
            legacyIds: s.entrada.legacyIds,
            abas: s.entrada.abas,
          ),
        );
        expect(forced.isUnlocked(f), isTrue, reason: s.label);
      }
    });
  });
}
