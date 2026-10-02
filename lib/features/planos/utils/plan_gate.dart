import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/fx_plan_lock_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/utils/dashboard_home_client_cache.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../data/planos_repository.dart';
import '../providers/plano_features_provider.dart';

/// API única de gating por recurso do plano (`recursos` de `/planos/me`).
///
/// Plano ainda desconhecido (carregando, sem cache) conta como liberado: a
/// tela de destino tem [FeatureGate] e decide com o plano real.
abstract final class PlanGate {
  static PlanoFeatures? _known(PlanoFeatures? fromProvider) =>
      (fromProvider ?? DashboardHomeClientCache.getIfFresh()?.planoFeatures)
          ?.normalizeForTier();

  static PlanoRecurso resolve(PlanoFeatures? features, String key) {
    final k = PlanoRecursoKeys.fromCapability(key) ?? key;
    if (features == null) {
      return PlanoRecurso(
        liberado: true,
        planoMinimo: PlanoRecursoKeys.matrix[k] ?? SubscriptionPlan.PRO,
      );
    }
    return features.recurso(k);
  }

  /// Para `build`: reconstrói quando o plano muda.
  static PlanoRecurso watch(WidgetRef ref, String key) =>
      resolve(_known(ref.watch(planoFeaturesProvider).value), key);

  /// Para callbacks (tap).
  static PlanoRecurso read(WidgetRef ref, String key) =>
      resolve(_known(ref.read(planoFeaturesProvider).value), key);

  static String tierLabel(SubscriptionPlan plan) =>
      plan == SubscriptionPlan.ENTERPRISE ? 'Enterprise' : 'Pro';

  /// Trailing de tile trancado, ou `null` quando liberado.
  static Widget? lockTrailing(
    PlanoRecurso recurso, {
    Color? brand,
    Color? mute,
  }) {
    if (recurso.liberado) return null;
    return FxPlanLockTrailing(
      tier: tierLabel(recurso.planoMinimo),
      brand: brand,
      mute: mute,
    );
  }

  /// Selo compacto para grid/botão, ou `null` quando liberado.
  static Widget? lockBadge(PlanoRecurso recurso, {Color? brand}) {
    if (recurso.liberado) return null;
    return FxPlanLockBadge(
      tier: tierLabel(recurso.planoMinimo),
      brand: brand,
      compact: true,
    );
  }

  /// `true` = pode seguir. Trancado: abre a sheet de upgrade do plano mínimo
  /// (personal) ou não faz nada (aluno nunca vê paywall).
  static Future<bool> guard(
    BuildContext context,
    WidgetRef ref,
    String key, {
    required String featureName,
    String source = 'plan_gate',
  }) async {
    final recurso = read(ref, key);
    if (recurso.liberado) return true;
    if (ref.read(authProvider.notifier).currentRole == UserRole.aluno) {
      return false;
    }
    await UpgradePromptSheet.show(
      context: context,
      featureName: featureName,
      capability: PlanoRecursoKeys.fromCapability(key) ?? key,
      requiredPlan: recurso.planoMinimo,
      upgradePlano: recurso.planoMinimo,
      source: source,
    );
    return false;
  }

  /// Envolve um `onTap`: só executa [action] quando o recurso está liberado.
  static VoidCallback tap(
    BuildContext context,
    WidgetRef ref,
    String key, {
    required String featureName,
    required VoidCallback action,
    String source = 'plan_gate',
  }) {
    return () async {
      final ok = await guard(
        context,
        ref,
        key,
        featureName: featureName,
        source: source,
      );
      if (ok) action();
    };
  }
}
