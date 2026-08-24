import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';

/// Banner de trial Enterprise com countdown e CTA de conversão.
class TrialCountdownBanner extends ConsumerWidget {
  const TrialCountdownBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(planoFeaturesProvider).valueOrNull;
    if (features == null) return const SizedBox.shrink();

    return FutureBuilder<TrialStatus>(
      future: ref.read(planosRepositoryProvider).getTrialStatus(),
      builder: (context, snap) {
        final trial = snap.data;
        if (trial == null || !trial.trialAtivo) return const SizedBox.shrink();

        final dias = trial.diasRestantes;
        final primary = Theme.of(context).colorScheme.primary;
        final warn = dias <= 3 ? EagleTokens.warn : primary;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s5,
            0,
            TokensStrip.s5,
            8,
          ),
          child: Material(
            color: warn.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap:
                  () => context.push(
                    '/assinatura',
                    extra: SubscriptionPlan.ENTERPRISE.apiName,
                  ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: warn),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dias <= 1
                                ?         'Trial Enterprise acaba hoje'
                                : 'Trial Enterprise · $dias dias restantes',
                            style: FocuxHubTypography.bodyMuted(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Assine para manter IA, financeiro e automações.',
                            style: FocuxHubTypography.bodyMuted(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: primary),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
