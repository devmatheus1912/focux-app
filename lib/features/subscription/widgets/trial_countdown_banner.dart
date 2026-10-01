import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../models/subscription_plan.dart';

final _trialStatusProvider = FutureProvider.autoDispose<TrialStatus>(
  (ref) => ref.read(planosRepositoryProvider).getTrialStatus(),
);

/// Banner do teste grátis com countdown e CTA de conversão.
class TrialCountdownBanner extends ConsumerWidget {
  const TrialCountdownBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(planoFeaturesProvider).value;
    if (features == null) return const SizedBox.shrink();

    final trial = ref.watch(_trialStatusProvider).value;
    if (trial == null || !trial.trialAtivo) return const SizedBox.shrink();

    final dias = trial.diasRestantes;
    final plano = PaywallCatalog.displayPlanName(trial.planoAtual);
    final primary = Theme.of(context).colorScheme.primary;
    final warn = dias <= 3 ? EagleTokens.warn : primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        0,
        FxSettingsLayout.pageInset,
        TokensStrip.s4,
      ),
      child: Material(
        color: warn.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
          onTap:
              () => context.push('/assinatura', extra: trial.planoAtual.apiName),
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
                            ? 'Teste $plano acaba hoje'
                            : 'Teste $plano · $dias dias restantes',
                        style: FocuxHubTypography.bodyMuted(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Assine para manter IA, PIX e Command Center.',
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
  }
}
