import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../providers/aderencia_provider.dart';
import '../utils/dashboard_home_focus.dart';
import '../utils/dashboard_readability.dart';

class DashboardAderenciaSemanaWidget extends StatelessWidget {
  final bool isDark;
  final List<AderenciaAlunoResumo> items;
  final bool retentionFocus;
  final bool suppressEmptyActions;

  const DashboardAderenciaSemanaWidget({
    super.key,
    required this.isDark,
    this.items = const [],
    this.retentionFocus = false,
    this.suppressEmptyActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final rowAccent = BrandPalette.sectionAccent(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dashboardReadableMuted(context, isDark: isDark);

    if (items.isEmpty) {
      return DashboardAderenciaSemanaEmptyCard(
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
      );
    }

    final semanaParada = items.every((a) => a.totalCheckinsSemana == 0);
    if (semanaParada) {
      return DashboardAderenciaSemanaEmptyCard(
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
            suppressEmptyActions || retentionFocus ? null : 'Plano retomada',
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
      );
    }

    return Container(
      decoration: fxStripCardDecoration(
        context,
        accent: primary,
        radius: FxSettingsLayout.groupRadius,
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final a = items[index];
          final nome = fxTitleCaseName(a.nome);
          return Semantics(
            button: true,
            label:
                '$nome. ${a.objetivo ?? 'Objetivo'}. '
                '${a.totalCheckinsSemana} check-ins. '
                'Aderência ${a.aderenciaPercent} por cento. '
                'Abrir aluno',
            child: InkWell(
              onTap: () => context.push('/alunos/${a.alunoId}'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TokensStrip.s4,
                  vertical: TokensStrip.s3,
                ),
                decoration: BoxDecoration(
                  border:
                      index < items.length - 1
                          ? Border(
                            bottom: BorderSide(
                              color:
                                  isDark
                                      ? EagleTokens.darkLine
                                      : TokensStrip.borderDefault,
                              width: 0.5,
                            ),
                          )
                          : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: primarySoft,
                      child: Text(
                        fxInitials(a.nome),
                        style: FocuxHubTypography.chip(rowAccent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: FocuxHubTypography.cardTitle(color: ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${a.objetivo ?? 'Objetivo'} · ${a.totalCheckinsSemana} check-ins',
                            style: FocuxHubTypography.bodyMuted(color: mute),
                          ),
                        ],
                      ),
                    ),
                    FxSparkline(
                      data: a.sparkline,
                      width: 56,
                      height: 22,
                      color: rowAccent,
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${a.aderenciaPercent}%',
                        textAlign: TextAlign.right,
                        style: FocuxHubTypography.metric(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
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
  /// Dia de retenção: card sem ícone/CTA — não compete com o Foco.
  final bool quiet;
  final String? primaryAction;
  final VoidCallback? onPrimary;
  final String? secondaryAction;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
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
                    style: FocuxHubTypography.cardTitle(color: chrome.ink),
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
