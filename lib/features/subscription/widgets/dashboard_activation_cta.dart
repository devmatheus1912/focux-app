import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../onboarding/widgets/setup_step_widgets.dart';

/// Alerta de ativação quando o personal ainda não extraiu valor do app.
class DashboardActivationCta extends StatelessWidget {
  const DashboardActivationCta({
    super.key,
    required this.alunosAtivos,
    required this.temTreinos,
    required this.temFinanceiro,
  });

  final int alunosAtivos;
  final bool temTreinos;
  final bool temFinanceiro;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    ({String title, String body, String cta, String route})? step;

    if (alunosAtivos == 0) {
      step = (
        title: 'Importe seus alunos',
        body: 'Migração em cerca de 2 min',
        cta: 'Importar alunos',
        route: '/growth/migracao',
      );
    } else if (!temTreinos) {
      step = (
        title: 'Atribua o primeiro treino',
        body: 'Gere com IA ou use um template',
        cta: 'Criar treino',
        route: '/treinos/novo',
      );
    } else if (!temFinanceiro) {
      step = (
        title: 'Lance a primeira mensalidade',
        body: 'PIX automático + lembrete',
        cta: 'Abrir financeiro',
        route: '/financeiro',
      );
    }

    if (step == null) return const SizedBox.shrink();

    final activeStep = step;
    final chrome = ShellChrome.of(context);
    final brand = BrandPalette.softened(primary);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        0,
        FxSettingsLayout.pageInset,
        TokensStrip.s3,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
          onTap: () {
            HapticFeedback.selectionClick();
            AnalyticsService.instance.track(
              ProductEvents.activationCtaTapped,
              props: {'route': activeStep.route, 'source': 'home_activation'},
            );
            context.push(normalizeSetupActionRoute(activeStep.route));
          },
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
            child: Semantics(
              button: true,
              label: '${activeStep.title}. ${activeStep.cta}',
              child: ConstrainedBox(
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
                            activeStep.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FocuxHubTypography.cardTitle(
                              color: chrome.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeStep.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FocuxHubTypography.bodyMuted(
                              color: chrome.mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: FxSettingsLayout.chevronSize,
                      color: chrome.mute,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
