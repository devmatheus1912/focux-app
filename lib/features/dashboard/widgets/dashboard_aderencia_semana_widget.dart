import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

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
  final bool retentionFocus;
  final bool suppressEmptyActions;

  const DashboardAderenciaSemanaWidget({
    super.key,
    required this.isDark,
    this.retentionFocus = false,
    this.suppressEmptyActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final rowAccent = BrandPalette.sectionAccent(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    return Consumer(
      builder: (context, ref, _) {
        final mute = dashboardReadableMuted(context, isDark: isDark);
        final async = ref.watch(aderenciaTop3Provider);
        return async.when(
          loading:
              () => Container(
                height: 184,
                padding: const EdgeInsets.all(14),
                decoration: fxStripCardDecoration(
                  context,
                  radius: TokensStrip.rCard,
                ),
                child: Column(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Shimmer.fromColors(
                        baseColor: primary.withValues(alpha: 0.08),
                        highlightColor: primary.withValues(alpha: 0.18),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 54,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
          error:
              (e, _) => Container(
                padding: const EdgeInsets.all(TokensStrip.s4),
                decoration: fxStripCardDecoration(
                  context,
                  radius: TokensStrip.rCard,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: EagleTokens.bad.withValues(
                          alpha: isDark ? 0.18 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: EagleTokens.bad,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Falha ao carregar aderência',
                            style: TextStyle(
                              color: ink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verifique sua conexão e puxe para atualizar.',
                            style: TextStyle(
                              color: mute,
                              fontSize: TokensStrip.fontBodySm,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          data: (items) {
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
                        : (retentionFocus
                            ? 'Ver alunos em risco'
                            : 'Ver agenda'),
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
                              style: TextStyle(
                                color: rowAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fxTitleCaseName(a.nome),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ink,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${a.objetivo ?? 'Objetivo'} · ${a.totalCheckinsSemana} check-ins',
                                  style: TextStyle(
                                    fontSize: TokensStrip.fontBodySm,
                                    color: mute,
                                  ),
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
                              style: AppTypography.mono(
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
          },
        );
      },
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        color: mute,
                        height: 1.35,
                        fontSize: TokensStrip.fontBodySm,
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
                              style: const TextStyle(
                                fontSize: TokensStrip.fontBodySm,
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
