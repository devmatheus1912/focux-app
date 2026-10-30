import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../planos/data/plano_recurso.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_inline_retry_tile.dart';
import '../../../l10n/app_localizations.dart';
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
    final plano = ref.watch(planoFeaturesProvider).value?.normalizeForTier();

    return statusAsync.when(
      loading: () => const Padding(
        padding: DashboardLayout.foldCard,
        child: SetupWizardSkeleton(),
      ),
      // Gate/cota de plano não é falha de carregamento.
      error:
          (e, _) =>
              isPlanRestrictionError(e)
                  ? const SizedBox.shrink()
                  : Padding(
                    padding: DashboardLayout.foldCard,
                    child: FxInlineRetryTile(
                      message: S.of(context).setupAtivacaoFalhou,
                      margin: EdgeInsets.zero,
                      onRetry: () => ref.invalidate(onboardingStatusProvider),
                    ),
                  ),
      data: (data) {
        if (data.ativacaoCompleta()) {
          return SetupSugestaoStrip(
            data: data,
            podeCobrar: plano?.recurso(PlanoRecursoKeys.carteira).liberado ?? false,
            temLanding: plano?.recurso(PlanoRecursoKeys.landing).liberado ?? false,
          );
        }

        final next = nextSetupStep(data);
        final feitas = data.etapasFeitas();
        final total = data.etapasTotal();
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

/// Uma sugestão por vez depois da ativação; dispensada não volta.
class SetupSugestaoStrip extends ConsumerStatefulWidget {
  const SetupSugestaoStrip({
    super.key,
    required this.data,
    required this.podeCobrar,
    required this.temLanding,
  });

  final OnboardingStatusData data;
  final bool podeCobrar;
  final bool temLanding;

  @override
  ConsumerState<SetupSugestaoStrip> createState() => _SetupSugestaoStripState();
}

class _SetupSugestaoStripState extends ConsumerState<SetupSugestaoStrip> {
  static const _chave = 'setup_sugestoes_dispensadas';
  Set<String>? _dispensadas;

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _dispensadas = (prefs.getStringList(_chave) ?? []).toSet());
  }

  Future<void> _dispensar(String id) async {
    final novas = {...?_dispensadas, id};
    setState(() => _dispensadas = novas);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_chave, novas.toList());
  }

  @override
  Widget build(BuildContext context) {
    final dispensadas = _dispensadas;
    if (dispensadas == null) return const SizedBox.shrink();
    final sugestao = setupProximaSugestao(
      widget.data,
      podeCobrar: widget.podeCobrar,
      temLanding: widget.temLanding,
      dispensadas: dispensadas,
    );
    if (sugestao == null) return const SizedBox.shrink();
    return Padding(
      padding: DashboardLayout.foldCard,
      child: FxSatelliteListTile(
        title: sugestao.title,
        titleCase: false,
        trailing: IconButton(
          tooltip: 'Dispensar',
          onPressed: () => _dispensar(sugestao.id),
          icon: const Icon(Icons.close_rounded),
        ),
        onTap: () => pushSetupActionRoute(context, ref, sugestao.rota),
      ),
    );
  }
}
