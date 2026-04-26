import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/subscription/models/subscription_plan.dart';
import '../../features/planos/providers/plano_features_provider.dart';

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

    if (featuresAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final features = featuresAsync.valueOrNull;
    final currentPlan = features?.plano ?? SubscriptionPlan.FREE;

    final hasAccess = capability != null && features != null
        ? _resolveCapability(features, capability!)
        : currentPlan.canAccess(requiredPlan);

    if (hasAccess) {
      return child;
    }

    if (lockedBuilder != null) {
      return lockedBuilder!;
    }

    // Default Locked UI
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Acesso Restrito',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'A funcionalidade "$featureName" requer o plano ${requiredPlan.name}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/paywall'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B4A9E),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Fazer Upgrade Agora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  bool _resolveCapability(PlanoFeatures f, String cap) {
    switch (cap) {
      case 'financeiro': return f.financeiro;
      case 'agenda': return f.agenda;
      case 'relatorios': return f.relatorios;
      case 'whiteLabel': return f.whiteLabel;
      case 'iaCopiloto': return f.iaCopiloto;
      case 'iaIlimitada': return f.iaIlimitada;
      default: return false;
    }
  }
}
