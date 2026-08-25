import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/onboarding_status_data.dart';
import '../data/setup_steps_catalog.dart';
import '../providers/onboarding_provider.dart';
import '../../perfil/providers/perfil_provider.dart';
import '../../dashboard/utils/dashboard_command_copy.dart';
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
      loading: () => const SetupWizardSkeleton(compact: true),
      error: (e, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.ativacaoCompleta) return const SizedBox.shrink();

        final next = nextSetupStep(data);
        final preview = dashboardSetupPreview(data);
        final hiddenPending = hiddenPendingSetupCount(data);
        final completedCount = data.etapasFeitas;
        final brand = BrandPalette.softened(primary);

        return Container(
          margin: const EdgeInsets.only(bottom: TokensStrip.s4),
          padding: const EdgeInsets.all(TokensStrip.s4),
          decoration: fxListCardDecoration(
            context,
            accent: brand,
            radius: FxSettingsLayout.groupRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sua ativação',
                    style: FocuxHubTypography.eyebrow(context, color: brand),
                  ),
                  TextButton(
                    onPressed: () => context.push('/onboarding/wizard'),
                    child: Text(
                      'Ver tudo',
                      style: FocuxHubTypography.chip(brand),
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
              if (completedCount > 0) ...[
                const SizedBox(height: TokensStrip.s2),
                Text(
                  '${dashboardCountLabel(completedCount, 'passo concluído', 'passos concluídos')} · foco nos próximos',
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
              ],
              const SizedBox(height: TokensStrip.s3),
              ...preview.asMap().entries.map(
                (entry) => SetupStepEntrance(
                  index: entry.key,
                  child: SetupStepCard(
                    variant: SetupStepCardVariant.compact,
                    title: entry.value.title,
                    icon: entry.value.icon,
                    completed: false,
                    onTap: () => _openStep(context, ref, entry.value),
                  ),
                ),
              ),
              if (hiddenPending > 0) ...[
                const SizedBox(height: TokensStrip.s2),
                Semantics(
                  button: true,
                  label:
                      'Mais $hiddenPending passos pendentes, abrir setup completo',
                  child: InkWell(
                    onTap: () => context.push('/onboarding/wizard'),
                    borderRadius: BorderRadius.circular(TokensStrip.rInput),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '+ $hiddenPending passo${hiddenPending > 1 ? 's' : ''} no setup completo',
                            style: FocuxHubTypography.chip(brand),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: FxSettingsLayout.chevronSize,
                            color: brand,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
