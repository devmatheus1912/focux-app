import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../planos/providers/plano_features_provider.dart';
import '../models/subscription_plan.dart';
import '../widgets/upgrade_prompt_sheet.dart';

/// Abre o editor de landing ou paywall de upgrade (somente Enterprise).
Future<void> openLandingEditorOrUpgrade(
  BuildContext context,
  WidgetRef ref,
) async {
  final features = ref.read(planoFeaturesProvider).valueOrNull;
  if (features?.landingCompleta == true) {
    if (context.mounted) context.push('/perfil/landing-editor');
    return;
  }
  if (!context.mounted) return;
  await UpgradePromptSheet.showIfAllowed(
    context: context,
    featureName: 'Landing page completa',
    capability: 'landingCompleta',
    requiredPlan: SubscriptionPlan.ENTERPRISE,
  );
}
