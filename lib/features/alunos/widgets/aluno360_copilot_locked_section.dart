import 'package:flutter/material.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../subscription/plan_entitlements.dart';
import '../constants/aluno_360_layout.dart';
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
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
            child: DecoratedBox(
              decoration: fxListCardDecoration(
                context,
                radius: FxSettingsLayout.groupRadius - 4,
              ),
              child: Padding(
                padding: const EdgeInsets.all(TokensStrip.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recurso do plano $planLabel',
                                style: Aluno360Layout.panelTitleStyle(
                                  context,
                                  ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gere a prioridade do dia com IA Copiloto para '
                                'cada aluno — faça upgrade para desbloquear.',
                                style: Aluno360Layout.captionStyle(
                                  context,
                                ).copyWith(color: mute, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed:
                          () => Aluno360CopilotUpgradeSheet.show(
                            context,
                            primary: primary,
                          ),
                      icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: Text('Conhecer o plano $planLabel'),
                      style: Aluno360Layout.operacaoOutlinedButtonStyle(
                        context,
                        primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            () => Aluno360CopilotUpgradeSheet.show(
                              context,
                              primary: primary,
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
            ),
          ),
        ],
      ),
    );
  }
}
