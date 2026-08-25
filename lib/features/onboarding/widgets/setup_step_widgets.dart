import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

IconData setupStepIcon(String name) {
  switch (name) {
    case 'person':
      return Icons.person_outline_rounded;
    case 'person_add':
      return Icons.person_add_outlined;
    case 'fitness_center':
      return Icons.fitness_center_rounded;
    case 'inventory_2':
      return Icons.inventory_2_outlined;
    case 'repeat':
      return Icons.repeat_rounded;
    case 'attach_money':
      return Icons.attach_money_rounded;
    case 'link':
      return Icons.link_rounded;
    default:
      return Icons.check_circle_outline_rounded;
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

bool setupStepUsesMaterialIcon(String name) =>
    name == 'person' || name == 'person_add' || name == 'link';

/// Hero de progresso — mesmo vidro e raio dos grupos inset.
class SetupProgressHeroCard extends StatelessWidget {
  const SetupProgressHeroCard({
    super.key,
    required this.progressPercent,
    required this.completedCount,
    required this.totalCount,
    this.nextActionLabel,
  });

  final int progressPercent;
  final int completedCount;
  final int totalCount;
  final String? nextActionLabel;

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
          TokensStrip.s4,
          TokensStrip.s4,
          TokensStrip.s3 + 2,
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
              nextActionLabel: nextActionLabel,
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
    this.nextActionLabel,
    this.compact = false,
    this.animateValue = true,
  });

  final int progressPercent;
  final int completedCount;
  final int totalCount;
  final String? nextActionLabel;
  final bool compact;
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
              minHeight: 8,
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
          if (!compact &&
              nextActionLabel != null &&
              nextActionLabel!.isNotEmpty)
            Text(
              'Próximo: $nextActionLabel',
              style: FocuxHubTypography.bodyMuted(
                color: chrome.mute,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (compact) ...[
            Text(
              '$completedCount de $totalCount passos · complete para liberar todo o fluxo.',
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ],
          const SizedBox(height: TokensStrip.s3),
          progressBar,
        ],
      ),
    );
  }
}

enum SetupStepCardVariant { full, compact }

class SetupStepCard extends StatelessWidget {
  const SetupStepCard({
    super.key,
    required this.title,
    required this.icon,
    required this.completed,
    this.description,
    this.estimatedMinutes,
    this.onTap,
    this.variant = SetupStepCardVariant.full,
    this.isLead = false,
    this.showDivider = true,
  });

  final String title;
  final String icon;
  final bool completed;
  final String? description;
  final int? estimatedMinutes;
  final VoidCallback? onTap;
  final SetupStepCardVariant variant;
  final bool isLead;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    if (variant == SetupStepCardVariant.compact) {
      return _SetupStepCompactRow(
        title: title,
        icon: icon,
        completed: completed,
        onTap: completed ? null : onTap,
      );
    }

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
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: FxSettingsLayout.rowLabel(color: ink),
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: FocuxHubTypography.bodyMuted(
                                color: chrome.mute,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (minutes.isNotEmpty) ...[
                      const SizedBox(width: TokensStrip.s2),
                      Text(
                        minutes,
                        style: FxSettingsLayout.rowValue(color: chrome.mute),
                      ),
                    ],
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
              : minutes.isEmpty
              ? '$title, pendente, toque para abrir'
              : '$title, pendente, $minutes, toque para abrir',
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

class _SetupStepCompactRow extends StatelessWidget {
  const _SetupStepCompactRow({
    required this.title,
    required this.icon,
    required this.completed,
    this.onTap,
  });

  final String title;
  final String icon;
  final bool completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final brand = BrandPalette.softened(Theme.of(context).colorScheme.primary);

    return Semantics(
      button: !completed,
      enabled: !completed,
      label: completed ? '$title, concluído' : title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              completed
                  ? null
                  : () {
                    HapticFeedback.selectionClick();
                    onTap?.call();
                  },
          borderRadius: BorderRadius.circular(TokensStrip.rInput),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: FxSettingsLayout.rowMinHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: TokensStrip.s1),
              child: Row(
                children: [
                  _SetupStepLeadingIcon(
                    icon: icon,
                    completed: completed,
                    color: completed ? brand.withValues(alpha: 0.7) : brand,
                  ),
                  const SizedBox(width: FxSettingsLayout.iconGap),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.cardTitle(
                        color: completed ? chrome.mute : chrome.ink,
                      ),
                    ),
                  ),
                  if (!completed)
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
    if (completed) {
      return FxIcon(
        name: 'circle-check',
        size: FxSettingsLayout.iconSize,
        color: color,
      );
    }
    if (setupStepUsesMaterialIcon(icon)) {
      return Icon(
        setupStepIcon(icon),
        size: FxSettingsLayout.iconSize,
        color: color,
      );
    }
    return FxIcon(
      name: setupStepFxIconName(icon),
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
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              height: compact ? 132 : 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entrada escalonada das linhas — respeita reduced motion.
class SetupStepEntrance extends StatelessWidget {
  const SetupStepEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotionOf(context)) return child;
    return child
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.035, curve: Curves.easeOutCubic, duration: 300.ms);
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
