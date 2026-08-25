import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';

/// Normaliza rotas do wizard para deep-links consistentes no app.
String normalizeSetupActionRoute(String route) {
  switch (route) {
    case '/treinos':
      return '/treinos/novo';
    case '/financeiro':
      return '/perfil/wallet';
    case '/perfil':
      return '/perfil/editar';
    default:
      return route;
  }
}

String setupStepFxIconName(String name) {
  switch (name) {
    case 'person':
      return 'target';
    case 'person_add':
      return 'users';
    case 'fitness_center':
      return 'dumbbell';
    case 'inventory_2':
      return 'article';
    case 'repeat':
      return 'route';
    case 'attach_money':
      return 'pix';
    case 'link':
      return 'spark';
    default:
      return 'circle-check';
  }
}

/// Hero de progresso — mesmo vidro e raio dos grupos inset.
class SetupProgressHeroCard extends StatelessWidget {
  const SetupProgressHeroCard({
    super.key,
    required this.progressPercent,
    required this.completedCount,
    required this.totalCount,
  });

  final int progressPercent;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final brand = BrandPalette.softened(primary);

    return DecoratedBox(
      decoration: fxListCardDecoration(
        context,
        accent: brand,
        radius: FxSettingsLayout.groupRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s3,
          TokensStrip.s4,
          TokensStrip.s3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sua ativação',
              style: FocuxHubTypography.eyebrow(context, color: brand),
            ),
            const SizedBox(height: TokensStrip.s2),
            SetupProgressHeader(
              progressPercent: progressPercent,
              completedCount: completedCount,
              totalCount: totalCount,
            ),
          ],
        ),
      ),
    );
  }
}

class SetupProgressHeader extends StatelessWidget {
  const SetupProgressHeader({
    super.key,
    required this.progressPercent,
    required this.completedCount,
    required this.totalCount,
    this.animateValue = true,
  });

  final int progressPercent;
  final int completedCount;
  final int totalCount;
  final bool animateValue;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final brand = BrandPalette.softened(primary);
    final chrome = ShellChrome.of(context);
    final value = totalCount > 0 ? completedCount / totalCount : 0.0;
    final reduceMotion = reduceMotionOf(context);

    final progressBar = ClipRRect(
      borderRadius: BorderRadius.circular(TokensStrip.rInput),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: Duration(
          milliseconds: reduceMotion || !animateValue ? 0 : 420,
        ),
        curve: Curves.easeOutCubic,
        builder:
            (_, v, __) => LinearProgressIndicator(
              value: v,
              backgroundColor: brand.withValues(alpha: 0.12),
              color: brand,
              minHeight: 4,
            ),
      ),
    );

    return Semantics(
      label:
          '$progressPercent por cento concluído, $completedCount de $totalCount passos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$progressPercent% concluído',
                style: FocuxHubTypography.sectionTitle(
                  context,
                  color: chrome.ink,
                ),
              ),
              Text(
                '$completedCount/$totalCount',
                style: FocuxHubTypography.metric(
                  color: brand,
                  fontSize: TokensStrip.fontBodySm,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s2),
          progressBar,
        ],
      ),
    );
  }
}

class SetupStepCard extends StatelessWidget {
  const SetupStepCard({
    super.key,
    required this.title,
    required this.icon,
    required this.completed,
    this.description,
    this.estimatedMinutes,
    this.onTap,
    this.isLead = false,
    this.showDivider = true,
  });

  final String title;
  final String icon;
  final bool completed;
  final String? description;
  final int? estimatedMinutes;
  final VoidCallback? onTap;
  final bool isLead;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final brand = BrandPalette.softened(Theme.of(context).colorScheme.primary);
    final highlight = isLead && !completed;
    final ink = completed ? chrome.mute : (highlight ? brand : chrome.ink);
    final minutes =
        !completed && estimatedMinutes != null
            ? '~$estimatedMinutes min'
            : '';
    final desc =
        !completed && description != null && description!.trim().isNotEmpty
            ? description!.trim()
            : '';

    final row = ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: FxSettingsLayout.rowMinHeight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SetupStepLeadingIcon(
            icon: icon,
            completed: completed,
            color: completed ? brand.withValues(alpha: 0.7) : brand,
          ),
          const SizedBox(width: FxSettingsLayout.iconGap),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border:
                    showDivider
                        ? Border(
                          bottom: BorderSide(
                            color: chrome.line,
                            width: FxSettingsLayout.dividerThickness,
                          ),
                        )
                        : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FxSettingsLayout.rowLabel(color: ink),
                                ),
                              ),
                              if (minutes.isNotEmpty) ...[
                                const SizedBox(width: TokensStrip.s2),
                                Text(
                                  minutes,
                                  style: FxSettingsLayout.rowValue(
                                    color: chrome.mute,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FocuxHubTypography.bodyMuted(
                                color: chrome.mute,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!completed) ...[
                      const SizedBox(width: TokensStrip.s1),
                      Icon(
                        Icons.chevron_right,
                        size: FxSettingsLayout.chevronSize,
                        color: chrome.mute,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: !completed,
      enabled: !completed,
      label:
          completed
              ? '$title, concluído'
              : [
                  title,
                  'pendente',
                  if (desc.isNotEmpty) desc,
                  if (minutes.isNotEmpty) minutes,
                  'toque para abrir',
                ].join(', '),
      child:
          completed
              ? row
              : InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap?.call();
                },
                child: row,
              ),
    );
  }
}

class _SetupStepLeadingIcon extends StatelessWidget {
  const _SetupStepLeadingIcon({
    required this.icon,
    required this.completed,
    required this.color,
  });

  final String icon;
  final bool completed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FxIcon(
      name: completed ? 'circle-check' : setupStepFxIconName(icon),
      size: FxSettingsLayout.iconSize,
      color: color,
    );
  }
}

class SetupWizardSkeleton extends StatelessWidget {
  const SetupWizardSkeleton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? EagleTokens.darkCard : TokensStrip.borderDefault;
    final highlight = isDark ? EagleTokens.darkCardHi : TokensStrip.pageBg;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 180,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 18),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    FxSettingsLayout.groupRadius,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Banner de conclusão quando todos os passos estão feitos.
class SetupAllDoneBanner extends StatelessWidget {
  const SetupAllDoneBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final brand = BrandPalette.softened(Theme.of(context).colorScheme.primary);

    return Semantics(
      liveRegion: true,
      label: 'Tudo configurado. Toque em Concluir setup.',
      child: Padding(
        padding: const EdgeInsets.only(bottom: FxSettingsLayout.groupGap),
        child: DecoratedBox(
          decoration: fxListCardDecoration(
            context,
            accent: brand,
            radius: FxSettingsLayout.groupRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensStrip.s4,
              vertical: TokensStrip.s3,
            ),
            child: Row(
              children: [
                FxIcon(name: 'spark', size: FxSettingsLayout.iconSize, color: brand),
                const SizedBox(width: FxSettingsLayout.iconGap),
                Expanded(
                  child: Text(
                    'Tudo configurado. Toque em Concluir setup.',
                    style: FocuxHubTypography.cardTitle(color: chrome.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip overlay — mesmo peso do sticky Perfil / Hoje. Não é CTA full-width.
class SetupWizardCta extends StatelessWidget {
  const SetupWizardCta({
    super.key,
    required this.label,
    required this.onPressed,
    required this.accent,
    required this.isDark,
  });

  final String label;
  final VoidCallback onPressed;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      end: TokensStrip.s4,
      bottom: TokensStrip.s4,
      child: SafeArea(
        top: false,
        child: DashboardHomeActionChip(
          label: label,
          accent: accent,
          isDark: isDark,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
