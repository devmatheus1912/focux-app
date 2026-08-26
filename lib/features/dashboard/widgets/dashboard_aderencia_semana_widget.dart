import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../constants/dashboard_layout.dart';
import '../providers/aderencia_provider.dart';
import '../utils/dashboard_home_focus.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';
import 'dashboard_section_header.dart';

class DashboardAderenciaSemanaWidget extends StatelessWidget {
  const DashboardAderenciaSemanaWidget({
    super.key,
    required this.isDark,
    this.items = const [],
    this.retentionFocus = false,
    this.suppressEmptyActions = false,
    this.showRelatorio = false,
    this.onOpenRelatorio,
  });

  final bool isDark;
  final List<AderenciaAlunoResumo> items;
  final bool retentionFocus;
  final bool suppressEmptyActions;
  final bool showRelatorio;
  final VoidCallback? onOpenRelatorio;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = dashboardReadableMuted(context, isDark: isDark);

    return Padding(
      padding: DashboardLayout.foldCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: DashboardMicrocopy.aderenciaDaSemana,
            actionLabel: showRelatorio ? 'Relatório' : null,
            onAction: showRelatorio ? onOpenRelatorio : null,
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          if (items.isEmpty)
            DashboardAderenciaSemanaEmptyCard(
              primary: primary,
              mute: mute,
              title: 'Sem check-ins nesta semana',
              body: DashboardAderenciaCopy.emptyBody(
                retentionFocus: retentionFocus,
              ),
              quiet: retentionFocus,
              primaryAction:
                  suppressEmptyActions
                      ? null
                      : (retentionFocus ? 'Ver alunos em risco' : 'Ver agenda'),
              onPrimary:
                  suppressEmptyActions
                      ? null
                      : (retentionFocus
                          ? () => context.go('/alunos?filtro=risco')
                          : () => context.go('/agenda')),
            )
          else if (items.every((a) => a.totalCheckinsSemana == 0))
            DashboardAderenciaSemanaEmptyCard(
              primary: primary,
              mute: mute,
              title: 'Treinos parados na semana',
              body: DashboardAderenciaCopy.stoppedBody(
                retentionFocus: retentionFocus,
              ),
              quiet: retentionFocus,
              primaryAction:
                  suppressEmptyActions
                      ? null
                      : (retentionFocus ? 'Revisar base' : 'Ver agenda'),
              secondaryAction:
                  suppressEmptyActions || retentionFocus
                      ? null
                      : 'Plano retomada',
              onPrimary:
                  suppressEmptyActions
                      ? null
                      : (retentionFocus
                          ? () => context.push('/retencao')
                          : () => context.go('/agenda')),
              onSecondary:
                  suppressEmptyActions || retentionFocus
                      ? null
                      : () => context.push('/dashboard/qualidade'),
            )
          else
            FxSettingsGroup(
              children: [
                for (var i = 0; i < items.length; i++)
                  _AderenciaTile(
                    item: items[i],
                    showDivider: i < items.length - 1,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AderenciaTile extends StatelessWidget {
  const _AderenciaTile({required this.item, required this.showDivider});

  final AderenciaAlunoResumo item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final nome = fxTitleCaseName(item.nome);
    final objetivo = item.objetivo?.trim();
    final subtitle = [
      if (objetivo != null && objetivo.isNotEmpty) objetivo,
      '${item.totalCheckinsSemana} check-ins',
    ].join(' · ');
    return FxSettingsTile(
      fxIcon: 'trend',
      label: nome,
      subtitle: subtitle,
      value: '${item.aderenciaPercent}%',
      numeric: true,
      showDivider: showDivider,
      semanticsLabel:
          '$nome. $subtitle. Aderência ${item.aderenciaPercent} por cento. Abrir aluno',
      onTap: () => context.push('/alunos/${item.alunoId}'),
    );
  }
}

class DashboardAderenciaSemanaEmptyCard extends StatelessWidget {
  const DashboardAderenciaSemanaEmptyCard({
    super.key,
    required this.primary,
    required this.mute,
    required this.title,
    required this.body,
    this.quiet = false,
    this.primaryAction,
    this.onPrimary,
    this.secondaryAction,
    this.onSecondary,
  });

  final Color primary;
  final Color mute;
  final String title;
  final String body;
  final bool quiet;
  final String? primaryAction;
  final VoidCallback? onPrimary;
  final String? secondaryAction;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final showPrimary = !quiet && primaryAction != null && onPrimary != null;
    final showSecondary =
        showPrimary && secondaryAction != null && onSecondary != null;

    if (!showPrimary) {
      return FxSettingsGroup(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: FxSettingsLayout.rowMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.cardTitle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.bodyMuted(color: mute),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return FxSettingsGroup(
      accent: primary,
      children: [
        FxSettingsTile(
          fxIcon: 'calendar',
          label: title,
          value: primaryAction!,
          onTap: onPrimary!,
          accent: primary,
          showDivider: showSecondary,
          semanticsLabel: '$title. $body. $primaryAction',
        ),
        if (showSecondary)
          FxSettingsTile(
            fxIcon: 'route',
            label: secondaryAction!,
            value: '',
            onTap: onSecondary!,
            accent: primary,
            showDivider: false,
          ),
      ],
    );
  }
}
