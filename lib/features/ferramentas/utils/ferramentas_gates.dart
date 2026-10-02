import '../../planos/data/plano_recurso.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';
import '../data/ferramentas_catalogo_models.dart';
import 'ferramentas_icons.dart';

String? capabilityFromFeatureGate(String? featureGate) {
  if (featureGate == null || featureGate.trim().isEmpty) return null;
  final raw = featureGate.trim();
  return PlanEntitlements.capabilityFromBackendFeature(raw) ??
      (raw.contains('_') ? null : raw);
}

/// Recurso do plano pela rota, para entradas do catálogo sem `featureGate`.
String? recursoFromRota(String? rotaApp) {
  final route = normalizeFerramentasRotaApp(rotaApp);
  return switch (route) {
    '/pacotes' || '/loja' => PlanoRecursoKeys.loja,
    '/perfil/landing-editor' => PlanoRecursoKeys.landing,
    '/leads' || '/leads/kanban' => PlanoRecursoKeys.leads,
    '/financeiro' || '/dunning' => PlanoRecursoKeys.financeiro,
    '/recorrencia' => PlanoRecursoKeys.recorrencia,
    '/perfil/wallet' => PlanoRecursoKeys.carteira,
    '/relatorio/business' || '/relatorios/global' => PlanoRecursoKeys.relatorios,
    '/habitos' => PlanoRecursoKeys.habitos,
    '/desafios' => PlanoRecursoKeys.desafios,
    '/automacoes' => PlanoRecursoKeys.automacoes,
    '/winback' => PlanoRecursoKeys.winback,
    '/perfil/equipe' => PlanoRecursoKeys.equipe,
    '/white-label' => PlanoRecursoKeys.whiteLabel,
    '/migracao-magica' => PlanoRecursoKeys.importacaoFoto,
    '/ia/copiloto' ||
    '/ia/chat' ||
    '/dashboard/command-center/copiloto' => PlanoRecursoKeys.ia,
    _ => null,
  };
}

/// `featureGate` do BFF; sem ele, recurso inferido pela rota.
String? capabilityFromEntrada(CatalogoEntrada entrada) =>
    capabilityFromFeatureGate(entrada.featureGate) ??
    recursoFromRota(entrada.rotaApp);

SubscriptionPlan upgradePlanFromEntrada(CatalogoEntrada entrada) {
  if (entrada.upgradePlano != null && entrada.upgradePlano!.isNotEmpty) {
    return subscriptionPlanFromApi(entrada.upgradePlano);
  }
  return PlanEntitlements.targetPlan(
    capability: capabilityFromEntrada(entrada),
    fallback: SubscriptionPlan.PRO,
  );
}
