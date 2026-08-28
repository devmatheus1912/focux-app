import 'package:flutter/material.dart';

import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../subscription/plan_entitlements.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../constants/aluno_360_layout.dart';

/// Prioridade do dia trancada — plano sem IA Copiloto.
class Aluno360CopilotLockedSection extends StatelessWidget {
  const Aluno360CopilotLockedSection({super.key, required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    final offer = PlanEntitlements.lockedOffer(
      featureName: 'Prioridade do dia',
      capability: 'iaCopiloto',
    );
    final mute = fxScreenMute(context);
    final ink = fxScreenInk(context);
    final planLabel =
        offer.targetPlan != null
            ? PlanEntitlements.displayPlanName(offer.targetPlan!)
            : 'Pro';

    return Semantics(
      container: true,
      label: 'Prioridade do dia indisponível no seu plano',
      child: FxSettingsGroup(
        header: 'Prioridade do dia',
        caption: 'Sugestão gerada com IA Copiloto',
        accent: primary,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline_rounded, size: 22, color: mute),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Recurso do plano $planLabel',
                        style: Aluno360Layout.panelTitleStyle(context, ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Disponível no plano $planLabel. Faça upgrade para gerar '
                        'a prioridade do dia com IA Copiloto.',
                        style: Aluno360Layout.captionStyle(
                          context,
                        ).copyWith(color: mute, height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              () => UpgradePromptSheet.show(
                                context: context,
                                featureName: 'Prioridade do dia',
                                capability: 'iaCopiloto',
                                requiredPlan: offer.targetPlan,
                                source: 'aluno360_copilot',
                              ),
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: Text(offer.ctaLabel),
                          style: Aluno360Layout.operacaoFilledButtonStyle(
                            context,
                            primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
