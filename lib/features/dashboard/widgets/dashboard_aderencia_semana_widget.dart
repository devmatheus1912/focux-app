import 'package:flutter/material.dart';
import '../../../core/theme/focux_hub_typography.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_icon.dart';
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
        isDark: isDark,
        primary: primary,
        mute: mute,
        title: 'Sem check-ins nesta semana',
        body: DashboardAderenciaCopy.emptyBody(
          retentionFocus: retentionFocus,
        ),
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
        isDark: isDark,
        primary: primary,
        mute: mute,
        title: 'Treinos parados na semana',
        body: DashboardAderenciaCopy.stoppedBody(
          retentionFocus: retentionFocus,
        ),
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
        radius: TokensStrip.rCard,
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final a = items[index];
          return InkWell(
            onTap: () => context.push('/alunos/${a.alunoId}'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
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
                          fxTitleCaseName(a.nome),
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
          );
        }),
      ),
    );
  }
}

class DashboardAderenciaSemanaEmptyCard extends StatelessWidget {
  const DashboardAderenciaSemanaEmptyCard({
    super.key,
    required this.isDark,
    required this.primary,
    required this.mute,
    required this.title,
    required this.body,
    this.primaryAction,
    this.onPrimary,
    this.secondaryAction,
    this.onSecondary,
  });

  final bool isDark;
  final Color primary;
  final Color mute;
  final String title;
  final String body;
  final String? primaryAction;
  final VoidCallback? onPrimary;
  final String? secondaryAction;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: FxIcon(
                    name: 'calendar',
                    size: 18,
                    color: BrandPalette.sectionAccent(primary, dark: isDark),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FocuxHubTypography.cardTitle(color: ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: FocuxHubTypography.bodyMuted(
                        color: mute,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (primaryAction != null && onPrimary != null) ...[
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 340;
                final primaryBtn = SizedBox(
                  width: stacked ? double.infinity : null,
                  child: FilledButton(
                    onPressed: onPrimary,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          TokensStrip.rButton,
                        ),
                      ),
                    ),
                    child: Text(primaryAction!),
                  ),
                );
                final secondaryBtn =
                    secondaryAction != null && onSecondary != null
                        ? SizedBox(
                          width: stacked ? double.infinity : null,
                          child: OutlinedButton(
                            onPressed: onSecondary,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  TokensStrip.rButton,
                                ),
                              ),
                            ),
                            child: Text(
                              secondaryAction!,
                              textAlign: TextAlign.center,
                              style: FocuxHubTypography.bodyMuted(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                        )
                        : null;

                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      primaryBtn,
                      if (secondaryBtn != null) ...[
                        const SizedBox(height: 8),
                        secondaryBtn,
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: primaryBtn),
                    if (secondaryBtn != null) ...[
                      const SizedBox(width: 8),
                      Expanded(child: secondaryBtn),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
