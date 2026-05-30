import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/feature_gate.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import 'pose_coach_panel.dart';

/// Pose Coach with Enterprise Pro gate + heuristic form hints.
class GatedPoseCoachPanel extends ConsumerWidget {
  const GatedPoseCoachPanel({
    super.key,
    required this.exerciseName,
    required this.targetReps,
    required this.brand,
    required this.dark,
    required this.onRepCompleted,
  });

  final String exerciseName;
  final int? targetReps;
  final Color brand;
  final bool dark;
  final VoidCallback onRepCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(planoFeaturesProvider).valueOrNull;
    if (features != null && !features.poseCoach) {
      return FeatureGate(
        featureName: 'Pose Coach',
        requiredPlan: SubscriptionPlan.ENTERPRISE_PRO,
        capability: 'poseCoach',
        lockedBuilder: _UpgradeHint(brand: brand, dark: dark),
        child: const SizedBox.shrink(),
      );
    }
    return PoseCoachPanel(
      exerciseName: exerciseName,
      targetReps: targetReps,
      brand: brand,
      dark: dark,
      onRepCompleted: onRepCompleted,
      enhancedFeedback: features?.poseCoach ?? false,
    );
  }
}

class _UpgradeHint extends StatelessWidget {
  const _UpgradeHint({required this.brand, required this.dark});
  final Color brand;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.lock_outline, color: brand),
      title: const Text('Pose Coach ML — Enterprise Pro'),
      subtitle: const Text('Análise de postura em tempo real'),
    );
  }
}
