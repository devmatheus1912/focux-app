import 'package:flutter/material.dart';

import '../../ia/data/ia_repository.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';

/// Plano insuficiente → paywall contextual (sem banner técnico).
Future<bool> surfaceAluno360IaUpgradeIfNeeded(
  BuildContext context,
  Object error,
) async {
  if (error is! IaOperationalException || !error.planUpgradeRequired) {
    return false;
  }
  await UpgradePromptSheet.show(
    context: context,
    featureName: 'Copiloto IA',
    capability: 'iaCopiloto',
    requiredPlan: error.suggestedUpgradePlan,
    source: 'aluno360_ia',
  );
  return true;
}
