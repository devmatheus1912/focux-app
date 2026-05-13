import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/subscription/models/subscription_plan.dart';
import '../../features/planos/providers/plano_features_provider.dart';
import '../../features/planos/data/planos_repository.dart';
import '../analytics/analytics_service.dart';
import '../router/role_home.dart';
import '../router/safe_navigation.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';

class FeatureGate extends ConsumerWidget {
  final SubscriptionPlan requiredPlan;
  final Widget child;
  final Widget? lockedBuilder;
  final String featureName;

  /// Capability flag específica (ex.: "iaCopiloto", "whiteLabel"). Quando
  /// passado, o gate consulta a flag no backend (via `/api/planos/me`)
  /// e ignora `requiredPlan`. Use isto para evitar inferir features a
  /// partir do nome do plano.
  final String? capability;

  const FeatureGate({
    super.key,
    required this.requiredPlan,
    required this.child,
    this.lockedBuilder,
    required this.featureName,
    this.capability,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuresAsync = ref.watch(planoFeaturesProvider);

    // BUG-01: em estado de loading, mostra indicador mas não bloqueia.
    if (featuresAsync.isLoading) {
      return const Center(child: FxLoading());
    }

    // BUG-01: em estado de erro, NÃO colapsar para FREE.
    // Usuário pagante não pode ser bloqueado por falha de rede.
    // Mostra tela de retry em vez de "Acesso Restrito".
    if (featuresAsync.hasError) {
      return _PlanSyncBannerShell(
        features: PlanoFeatures.optimisticEnterprise,
        onRefresh: () => ref.read(planoFeaturesProvider.notifier).refresh(),
        child: child,
      );
    }

    final features = featuresAsync.value;
    // Se value for null aqui (não deveria após hasError check), libera acesso
    // conservadoramente — melhor falhar aberto do que bloquear pagante.
    if (features == null) {
      return child;
    }

    final currentPlan = features.plano;

    final hasAccess =
        capability != null
            ? _resolveCapability(features, capability!)
            : currentPlan.canAccess(requiredPlan);

    if (hasAccess || features.fromCache) {
      if (!hasAccess && features.fromCache) {
        Future.microtask(
          () => AnalyticsService.instance.track(
            ProductEvents.featureGateBlocked,
            props: {
              'feature': featureName,
              'requiredPlan': requiredPlan.name,
              'currentPlan': currentPlan.name,
              'allowedByStaleCache': true,
            },
          ),
        );
      }
      return _PlanSyncBannerShell(
        features: features,
        onRefresh: () => ref.read(planoFeaturesProvider.notifier).refresh(),
        child: child,
      );
    }

    if (lockedBuilder != null) {
      return lockedBuilder!;
    }

    Future.microtask(
      () => AnalyticsService.instance.track(
        ProductEvents.featureGateBlocked,
        props: {
          'feature': featureName,
          'requiredPlan': requiredPlan.name,
          'currentPlan': currentPlan.name,
          'allowedByStaleCache': false,
        },
      ),
    );

    // BUG-02+11: Default Locked UI com Scaffold (back button) + CTA → /planos
    return _LockedScreen(featureName: featureName, requiredPlan: requiredPlan);
  }

  bool _resolveCapability(PlanoFeatures f, String cap) {
    switch (cap) {
      case 'financeiro':
        return f.financeiro;
      case 'agenda':
        return f.agenda;
      case 'relatorios':
        return f.relatorios;
      case 'whiteLabel':
        return f.whiteLabel;
      case 'iaCopiloto':
        return f.iaCopiloto;
      case 'iaIlimitada':
        return f.iaIlimitada;
      default:
        return false;
    }
  }
}

class _PlanSyncBannerShell extends StatelessWidget {
  final PlanoFeatures features;
  final VoidCallback onRefresh;
  final Widget child;

  const _PlanSyncBannerShell({
    required this.features,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final warning = features.syncWarning;
    if (!features.fromCache && warning == null) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 14,
          right: 14,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF111827).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFFB020).withValues(alpha: 0.28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: Color(0xFFFFD28A),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      warning ?? 'Plano salvo em cache. Atualizando...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.2,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atualizar plano',
                    visualDensity: VisualDensity.compact,
                    onPressed: onRefresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tela de acesso restrito ─────────────────────────────────────────────────

class _LockedScreen extends ConsumerWidget {
  final String featureName;
  final SubscriptionPlan requiredPlan;

  const _LockedScreen({required this.featureName, required this.requiredPlan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planLabel =
        requiredPlan == SubscriptionPlan.ENTERPRISE ? 'Enterprise' : 'Premium';

    return Scaffold(
      // BUG-02: AppBar com botão de voltar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () => safePopOr(context, () => goToRoleHome(context, ref)),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Acesso Restrito',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"$featureName" requer o plano $planLabel.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                // BUG-11: CTA → /planos (não /paywall)
                ElevatedButton(
                  onPressed: () => context.push('/planos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3454D1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ver planos',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed:
                      () =>
                          safePopOr(context, () => goToRoleHome(context, ref)),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
