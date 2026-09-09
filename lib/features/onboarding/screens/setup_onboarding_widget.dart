import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../dashboard/constants/dashboard_layout.dart';
import '../../dashboard/widgets/dashboard_home_activation_strip.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../data/onboarding_status_data.dart';
import '../data/setup_steps_catalog.dart';
import '../providers/onboarding_provider.dart';
import '../utils/setup_action_navigation.dart';
import '../widgets/setup_step_widgets.dart';

class SetupOnboardingWidget extends ConsumerWidget {
  const SetupOnboardingWidget({super.key, this.statusFromHome});

  final OnboardingStatusData? statusFromHome;

  Future<void> _openStep(
    BuildContext context,
    WidgetRef ref,
    SetupStepCatalogEntry entry,
  ) async {
    await pushSetupActionRoute(context, ref, entry.actionRoute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync =
        statusFromHome != null
            ? AsyncValue<OnboardingStatusData>.data(statusFromHome!)
            : ref.watch(onboardingStatusProvider);
    final landingCompleta =
        ref.watch(planoFeaturesProvider).valueOrNull?.landingCompleta ?? false;

    return statusAsync.when(
      loading: () => const Padding(
        padding: DashboardLayout.foldCard,
        child: SetupWizardSkeleton(),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.ativacaoCompleta(includeLinkBio: landingCompleta)) {
          return const SizedBox.shrink();
        }

        final next = nextSetupStep(data, landingCompleta: landingCompleta);
        final feitas = data.etapasFeitas(includeLinkBio: landingCompleta);
        final total = data.etapasTotal(includeLinkBio: landingCompleta);
        final nextTitle = next?.title ?? 'Continuar setup';
        final semantics =
            'Sua ativação, $feitas de $total. '
            'Próximo: $nextTitle. Toque para continuar';

        return Padding(
          padding: DashboardLayout.foldCard,
          child: DashboardHomeActivationStrip(
            title: 'Sua ativação',
            subtitle: nextTitle,
            trailingMetric: '$feitas/$total',
            progress: total > 0 ? feitas / total : 0.0,
            semanticsLabel: semantics,
            onTap: () {
              AnalyticsService.instance.track(
                ProductEvents.activationCtaTapped,
                props: {
                  'source': 'home_setup',
                  'route': next?.actionRoute ?? '/onboarding/wizard',
                },
              );
              if (next != null) {
                _openStep(context, ref, next);
              } else {
                context.push('/onboarding/wizard');
              }
            },
          ),
        );
      },
    );
  }
}
