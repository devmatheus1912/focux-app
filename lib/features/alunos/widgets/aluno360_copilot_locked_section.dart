import 'package:flutter/material.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../subscription/plan_entitlements.dart';
import 'aluno360_copilot_upgrade_sheet.dart';

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
    final planLabel =
        offer.targetPlan != null
            ? PlanEntitlements.displayPlanName(offer.targetPlan!)
            : 'Pro';

    return Semantics(
      container: true,
      label: 'Prioridade do dia indisponível no seu plano',
      child: FxSettingsGroup(
        header: 'Prioridade do dia',
        caption: 'Sugestão diária com IA Copiloto',
        accent: primary,
        footer: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FxSettingsLayout.groupPadH,
          ),
          child: Text(
            'Disponível no plano $planLabel · toque para assinar.',
            style: FxSettingsLayout.footer(color: mute),
          ),
        ),
        children: [
          FxSettingsTile(
            icon: Icons.auto_awesome_outlined,
            label: 'Prioridade com IA',
            subtitle: 'Sugestão personalizada com contexto do aluno',
            value: '',
            locked: true,
            upgradeTierLabel: planLabel,
            showDivider: false,
            onTap:
                () => Aluno360CopilotUpgradeSheet.show(
                  context,
                  primary: primary,
                ),
          ),
        ],
      ),
    );
  }
}
