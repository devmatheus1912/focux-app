import 'package:flutter/material.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/data/command_action_item.dart';
import '../../dashboard/widgets/command_action_tile.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final planLabel =
        offer.targetPlan != null
            ? PlanEntitlements.displayPlanName(offer.targetPlan!)
            : 'Pro';

    return Semantics(
      container: true,
      label: 'Prioridade do dia indisponível no seu plano',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardSectionHeader(title: 'Prioridade do dia'),
          const SizedBox(height: 4),
          Text(
            'Sugestão diária com IA Copiloto',
            style: FxSettingsLayout.footer(color: mute),
          ),
          const SizedBox(height: TokensStrip.s3),
          CommandActionTile(
            item: CommandActionItem(
              icon: 'zap',
              title: 'Prioridade com IA',
              subtitle: 'Sugestão personalizada com contexto do aluno',
              route: '/assinatura',
              tone: CommandActionTone.primary,
              priorityBadge: planLabel,
            ),
            isDark: isDark,
            primary: primary,
            showDivider: false,
            onTap:
                () => Aluno360CopilotUpgradeSheet.show(
                  context,
                  primary: primary,
                ),
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            'Disponível no plano $planLabel · toque para assinar.',
            style: FxSettingsLayout.footer(color: mute),
          ),
        ],
      ),
    );
  }
}
