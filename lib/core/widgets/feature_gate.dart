import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/utils/dashboard_home_client_cache.dart';
import '../../features/planos/utils/plano_capability.dart';
import '../../features/subscription/models/subscription_plan.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/planos/providers/plano_features_provider.dart';
import '../../features/planos/data/planos_repository.dart';
import '../../features/subscription/plan_entitlements.dart';
import '../analytics/analytics_service.dart';
import '../router/role_home.dart';
import '../router/safe_navigation.dart';
import '../theme/design_tokens.dart';
import '../theme/shell_chrome.dart';
import 'fx_motion.dart';
import 'fx_shell_scaffold.dart';
import 'skeleton_loader.dart';

class FeatureGate extends ConsumerWidget {
  final SubscriptionPlan requiredPlan;
  final Widget child;
  final Widget? lockedBuilder;
  final String featureName;

  /// Capability flag específica (ex.: "financeiro", "iaCopiloto"). Quando
  /// passado, o gate consulta a flag no backend (via `/api/planos/me`).
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
    final fromProvider = featuresAsync.valueOrNull;
    final fromHome =
        fromProvider == null
            ? DashboardHomeClientCache.getIfFresh()?.planoFeatures
            : null;

    if (fromProvider == null && fromHome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (ref.read(planoFeaturesProvider).valueOrNull != null) return;
        ref.read(planoFeaturesProvider.notifier).seedFromHome(fromHome);
      });
    }

    final features = fromProvider ?? fromHome;
    if (features != null) {
      final gated = features.normalizeForTier();
      return _buildGatedContent(
        context: context,
        ref: ref,
        features: gated,
        hasAccess: _hasAccess(gated, requiredPlan, capability),
        featureName: featureName,
        capability: capability,
        requiredPlan: requiredPlan,
      );
    }

    if (featuresAsync.hasError) {
      final isAluno = ref.read(authProvider) == AuthStatus.authenticated &&
          ref.read(authProvider.notifier).currentRole == UserRole.aluno;
      // Fail-closed: nunca liberar Enterprise fantasma quando /planos/me falha.
      final fallback = (isAluno
              ? PlanoFeatures.optimisticAluno
              : PlanoFeatures.free)
          .normalizeForTier();
      return _buildGatedContent(
        context: context,
        ref: ref,
        features: fallback,
        hasAccess: _hasAccess(fallback, requiredPlan, capability),
        featureName: featureName,
        capability: capability,
        requiredPlan: requiredPlan,
      );
    }

    return const SkeletonList();
  }

  bool _hasAccess(
    PlanoFeatures features,
    SubscriptionPlan requiredPlan,
    String? capability,
  ) {
    if (capability != null) {
      return _resolveCapability(features, capability);
    }
    return features.plano.canAccess(requiredPlan);
  }

  Widget _buildGatedContent({
    required BuildContext context,
    required WidgetRef ref,
    required PlanoFeatures features,
    required bool hasAccess,
    required String featureName,
    required String? capability,
    required SubscriptionPlan requiredPlan,
  }) {
    if (hasAccess) {
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
          'capability': capability,
          'requiredPlan': requiredPlan.name,
          'currentPlan': features.plano.name,
          'allowedByStaleCache': false,
        },
      ),
    );

    return _LockedScreen(
      featureName: featureName,
      capability: capability,
      requiredPlan: requiredPlan,
    );
  }

  bool _resolveCapability(PlanoFeatures f, String cap) =>
      PlanoCapability.has(f, cap);
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
                color: EagleTokens.cinematicBgHi.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: EagleTokens.opsNotice.withValues(alpha: 0.28),
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
                  Icon(
                    Icons.cloud_off_rounded,
                    color: EagleTokens.warnDark,
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

class _LockedScreen extends ConsumerStatefulWidget {
  final String featureName;
  final String? capability;
  final SubscriptionPlan requiredPlan;

  const _LockedScreen({
    required this.featureName,
    this.capability,
    required this.requiredPlan,
  });

  @override
  ConsumerState<_LockedScreen> createState() => _LockedScreenState();
}

class _LockedScreenState extends ConsumerState<_LockedScreen> {
  @override
  void initState() {
    super.initState();
    // Locked screen is enough — no auto-sheet on mount (evita spam de upsell).
  }

  @override
  Widget build(BuildContext context) {
    final offer = PlanEntitlements.lockedOffer(
      featureName: widget.featureName,
      capability: widget.capability,
      requiredPlan: widget.requiredPlan,
    );
    final primary = Theme.of(context).colorScheme.primary;

    return FxShellScaffold(
      useMesh: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () => safePopOr(context, () => goToRoleHome(context, ref)),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: fxStripCardDecoration(context, accent: primary),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(Icons.lock_open_rounded, size: 32, color: primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      offer.headline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      offer.body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ShellChrome.of(context).mute,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FxLiquidPrimaryButton(
                label: offer.ctaLabel,
                icon: Icons.workspace_premium_rounded,
                onPressed:
                    offer.targetPlan == null
                        ? null
                        : () {
                          final cap = widget.capability;
                          final capQuery =
                              cap != null && cap.isNotEmpty
                                  ? '&capability=${Uri.encodeComponent(cap)}'
                                  : '';
                          context.push(
                            '/assinatura?plano=${offer.targetPlan!.apiName}&source=feature_gate&feature=${Uri.encodeComponent(widget.featureName)}$capQuery',
                          );
                        },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed:
                    () =>
                        safePopOr(context, () => goToRoleHome(context, ref)),
                child: const Text('Agora não'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
