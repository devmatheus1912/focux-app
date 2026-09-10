import 'package:flutter/material.dart';

import '../../subscription/widgets/upgrade_prompt_sheet.dart';

/// Sheet de upgrade — Prioridade do dia / IA Copiloto no Aluno 360.
/// Delega ao sheet canônico de venda (mesmo layout de todas as ferramentas).
class Aluno360CopilotUpgradeSheet {
  Aluno360CopilotUpgradeSheet._();

  static Future<void> show(
    BuildContext context, {
    required Color primary,
  }) {
    return UpgradePromptSheet.show(
      context: context,
      featureName: 'Prioridade do dia',
      capability: 'iaCopiloto',
      source: 'aluno360_copilot',
    );
  }
}
