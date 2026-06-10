import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../plan_entitlements.dart';

/// Aviso soft (~80% do limite) para converter antes do hard stop do backend.
class PlanUsageBanner extends ConsumerWidget {
  const PlanUsageBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(planoFeaturesProvider).valueOrNull;
    if (features == null) return const SizedBox.shrink();

    final usage = PlanEntitlements.snapshotFrom(
      plano: features.plano,
      alunosAtivos: features.alunosAtivos,
      limiteAlunos: features.limiteAlunos,
      iaUsadaMes: features.iaUsadaMes,
      limiteIaMensal: features.limiteIaMensal,
    );

    final message = PlanEntitlements.softGateMessage(usage);
    final target = PlanEntitlements.softGateTargetPlan(usage);
    if (message == null || target == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final warn = isDark ? const Color(0xFFFFD28A) : EagleTokens.warn;

    return Padding(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 0, TokensStrip.s5, 12),
      child: Material(
        color: warn.withValues(alpha: isDark ? 0.12 : 0.14),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/assinatura', extra: target.apiName),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.trending_up_rounded, color: warn, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usage.alunosAtLimit
                            ? 'Limite de alunos atingido'
                            : usage.iaAtLimit
                            ? 'Cota de IA esgotada'
                            : 'Você está perto do limite do plano',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color:
                              isDark
                                  ? EagleTokens.darkInk
                                  : TokensStrip.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color:
                              isDark
                                  ? EagleTokens.darkInkMute
                                  : TokensStrip.textSecondary,
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
