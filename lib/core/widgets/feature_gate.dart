import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/subscription/providers/subscription_provider.dart';
import '../../features/subscription/models/subscription_plan.dart';
import '../../features/subscription/screens/paywall_screen.dart';

class FeatureGate extends StatelessWidget {
  final SubscriptionPlan requiredPlan;
  final Widget child;
  final Widget? lockedBuilder;
  final String featureName;

  const FeatureGate({
    super.key,
    required this.requiredPlan,
    required this.child,
    this.lockedBuilder,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    final currentPlan = context.watch<SubscriptionProvider>().currentPlan;

    if (currentPlan.canAccess(requiredPlan)) {
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
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
              },
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
}
