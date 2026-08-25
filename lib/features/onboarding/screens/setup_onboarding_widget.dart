import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/onboarding_status_data.dart';
import '../data/setup_steps_catalog.dart';
import '../providers/onboarding_provider.dart';
import '../../perfil/providers/perfil_provider.dart';
import '../widgets/setup_step_widgets.dart';

class SetupOnboardingWidget extends ConsumerWidget {
  const SetupOnboardingWidget({super.key, this.statusFromHome});

  final OnboardingStatusData? statusFromHome;

  Future<void> _openStep(
    BuildContext context,
    WidgetRef ref,
    SetupStepCatalogEntry entry,
  ) async {
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync =
        statusFromHome != null
            ? AsyncValue<OnboardingStatusData>.data(statusFromHome!)
            : ref.watch(onboardingStatusProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);

    return statusAsync.when(
      loading: () => const SetupWizardSkeleton(),
      error: (e, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.ativacaoCompleta) return const SizedBox.shrink();

        final next = nextSetupStep(data);
        final brand = BrandPalette.softened(primary);
        final progress =
            data.etapasTotal > 0
                ? data.etapasFeitas / data.etapasTotal
                : 0.0;
        final nextTitle = next?.title ?? 'Continuar setup';
        final semantics =
            'Sua ativação, ${data.etapasFeitas} de ${data.etapasTotal}. '
            'Próximo: $nextTitle. Toque para continuar';

        return Material(
          color: Colors.transparent,
          child: Semantics(
            button: true,
            label: semantics,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
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
              borderRadius: BorderRadius.circular(
                FxSettingsLayout.groupRadius,
              ),
              child: Ink(
                decoration: fxListCardDecoration(
                  context,
                  accent: brand,
                  radius: FxSettingsLayout.groupRadius,
                ),
                padding: const EdgeInsets.fromLTRB(
                  TokensStrip.s4,
                  TokensStrip.s3,
                  TokensStrip.s3,
                  TokensStrip.s3,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: FxSettingsLayout.rowMinHeight,
                      ),
                      child: Row(
                        children: [
                          FxIcon(
                            name: 'spark',
                            size: FxSettingsLayout.iconSize,
                            color: brand,
                          ),
                          const SizedBox(width: FxSettingsLayout.iconGap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sua ativação',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FocuxHubTypography.cardTitle(
                                    color: chrome.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  nextTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FocuxHubTypography.bodyMuted(
                                    color: chrome.mute,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: TokensStrip.s2),
                          Text(
                            '${data.etapasFeitas}/${data.etapasTotal}',
                            style: FocuxHubTypography.metric(
                              color: brand,
                              fontSize: TokensStrip.fontBodySm,
                            ),
                          ),
                          const SizedBox(width: TokensStrip.s1),
                          Icon(
                            Icons.chevron_right,
                            size: FxSettingsLayout.chevronSize,
                            color: chrome.mute,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        TokensStrip.rInput,
                      ),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: brand.withValues(alpha: 0.12),
                        color: brand,
                      ),
                    ),
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
