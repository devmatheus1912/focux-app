import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/utils/dashboard_home_client_cache.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import 'pose_coach_panel.dart';

/// Pose Coach with Enterprise gate + heuristic form hints.
///
/// Mid-workout upsell is personal-facing only. For alunos without the
/// capability we show an honest hide (no Assinar CTA).
class GatedPoseCoachPanel extends ConsumerWidget {
  const GatedPoseCoachPanel({
    super.key,
    required this.exerciseName,
    required this.targetReps,
    required this.brand,
    required this.dark,
    required this.onRepCompleted,
    this.forAluno = false,
  });

  final String exerciseName;
  final int? targetReps;
  final Color brand;
  final bool dark;
  final VoidCallback onRepCompleted;
  final bool forAluno;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features =
        ref.watch(planoFeaturesProvider).valueOrNull ??
        DashboardHomeClientCache.getIfFresh()?.planoFeatures;
    return FeatureGate(
      featureName: 'Pose Coach',
      requiredPlan: SubscriptionPlan.ENTERPRISE,
      capability: 'poseCoach',
      lockedBuilder:
          forAluno
              ? _AlunoUnavailableHint(brand: brand)
              : _UpgradeHint(brand: brand, dark: dark),
      child: PoseCoachPanel(
        exerciseName: exerciseName,
        targetReps: targetReps,
        brand: brand,
        dark: dark,
        onRepCompleted: onRepCompleted,
        enhancedFeedback: features?.poseCoach ?? false,
      ),
    );
  }
}

class _UpgradeHint extends StatelessWidget {
  const _UpgradeHint({required this.brand, required this.dark});
  final Color brand;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return FxSatelliteListTile(
      title: 'Pose Coach — plano Enterprise do personal',
      titleCase: false,
      subtitle: const Text(
        'Análise de postura em tempo real no plano Enterprise da sua conta Focux.',
      ),
      leading: Icon(Icons.lock_outline, color: brand),
      accent: brand,
      margin: EdgeInsets.zero,
    );
  }
}

class _AlunoUnavailableHint extends StatelessWidget {
  const _AlunoUnavailableHint({required this.brand});
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return FxSatelliteListTile(
      title: 'Pose Coach indisponível neste treino',
      titleCase: false,
      subtitle: const Text(
        'Recurso do plano Enterprise do seu personal — não é uma assinatura sua.',
      ),
      leading: Icon(Icons.info_outline, color: brand),
      accent: brand,
      margin: EdgeInsets.zero,
    );
  }
}
