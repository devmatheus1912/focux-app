import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
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
            Column(
              children: [
                for (final item in items)
                  _AderenciaTile(item: item),
              ],
            ),
        ],
      ),
    );
  }
}

class _AderenciaTile extends StatelessWidget {
  const _AderenciaTile({required this.item});

  final AderenciaAlunoResumo item;

  @override
  Widget build(BuildContext context) {
    final nome = fxTitleCaseName(item.nome);
    final objetivo = item.objetivo?.trim();
    final subtitle = [
      if (objetivo != null && objetivo.isNotEmpty) objetivo,
      '${item.totalCheckinsSemana} check-ins',
    ].join(' · ');
    return Semantics(
      label:
          '$nome. $subtitle. Aderência ${item.aderenciaPercent} por cento. Abrir aluno',
      button: true,
      child: FxSatelliteListTile(
        title: nome,
        subtitle: Text(subtitle),
        trailing: Text(
          '${item.aderenciaPercent}%',
          style: FocuxHubTypography.bodyMuted(
            color: fxScreenMute(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: () => context.push('/alunos/${item.alunoId}'),
      ),
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
    final subtitle = Text(
      body,
      style: FocuxHubTypography.bodyMuted(color: mute),
    );

    if (!showPrimary) {
      return FxSatelliteListTile(
        title: title,
        subtitle: subtitle,
      );
    }

    return Column(
      children: [
        Semantics(
          label: '$title. $body. $primaryAction',
          button: true,
          child: FxSatelliteListTile(
            title: title,
            subtitle: subtitle,
            trailing: Text(
              primaryAction!,
              style: FocuxHubTypography.bodyMuted(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            accent: primary,
            onTap: onPrimary,
          ),
        ),
        if (showSecondary)
          FxSatelliteListTile(
            title: secondaryAction!,
            onTap: onSecondary,
          ),
      ],
    );
  }
}
