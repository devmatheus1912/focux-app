import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/setup_steps_catalog.dart';
import '../providers/onboarding_provider.dart';
import '../../perfil/providers/perfil_provider.dart';
import '../widgets/setup_step_widgets.dart';

class SetupOnboardingWidget extends ConsumerWidget {
  const SetupOnboardingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(onboardingStatusProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return statusAsync.when(
      loading: () => const SetupWizardSkeleton(compact: true),
      error: (e, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.ativacaoCompleta) return const SizedBox.shrink();

        final next = nextSetupStep(data);

        return Container(
          margin: const EdgeInsets.only(bottom: TokensStrip.s4),
          padding: const EdgeInsets.all(TokensStrip.s4),
          decoration: fxStripCardDecoration(
            context,
            accent: primary,
            radius: TokensStrip.rCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sua ativação',
                    style: TokensStrip.h2(
                      color: primary,
                      fontFamily:
                          Theme.of(context).textTheme.bodyLarge?.fontFamily,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/onboarding/wizard'),
                    child: Text(
                      'Ver tudo',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              SetupProgressHeader(
                progressPercent: data.progressoExibido,
                completedCount: data.etapasFeitas,
                totalCount: data.etapasTotal,
                nextActionLabel: next?.title,
                compact: true,
              ),
              const SizedBox(height: TokensStrip.s3),
              ...setupStepCatalog.map((entry) {
                final done = entry.isDone(data);
                return SetupStepCard(
                  variant: SetupStepCardVariant.compact,
                  title: entry.title,
                  icon: entry.icon,
                  completed: done,
                  onTap: () async {
                    if (entry.id == 'perfil') {
                      try {
                        final perfil = await ref.read(perfilProvider.future);
                        if (context.mounted) {
                          context.push('/perfil/editar', extra: perfil);
                        }
                      } catch (_) {
                        if (context.mounted) context.push('/perfil');
                      }
                      return;
                    }
                    if (context.mounted) {
                      context.push(entry.actionRoute);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
