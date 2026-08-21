import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../../dashboard/widgets/dashboard_hero_widgets.dart';

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
      return 'route';
    default:
      return 'circle-check';
  }
}

/// Hero de progresso — paridade visual com cards da Home.
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

    return DecoratedBox(
      decoration: fxStripCardDecoration(
        context,
        accent: primary,
        radius: TokensStrip.rCard,
        glowStrength: 0.08,
        emphasize: true,
      ),
      child: CustomPaint(
        foregroundPainter: const DashboardHeroGridPainter(lineAlpha: 0.05),
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
                'Ativação · setup D0',
                style: FocuxHubTypography.eyebrow(
                  context,
                  color: primary,
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
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
              backgroundColor: primary.withValues(alpha: 0.12),
              color: primary,
              minHeight: 8,
            ),
      ),
    );

    final header = Semantics(
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
                style: dashboardPageTitleStyle(
                  context,
                  color: ink,
                ).copyWith(
                  fontSize: compact ? 16 : 18,
                  letterSpacing: -0.35,
                ),
              ),
              Text(
                '$completedCount/$totalCount',
                style: TokensStrip.body(
                  color: primary,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: compact ? TokensStrip.s2 : 6),
          if (!compact &&
              nextActionLabel != null &&
              nextActionLabel!.isNotEmpty)
            Text(
              'Próximo: $nextActionLabel',
              style: dashboardCardSubtitleStyle(
                context,
                isDark: isDark,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          if (compact) ...[
            Text(
              '$completedCount de $totalCount passos · complete para liberar todo o fluxo.',
              style: TokensStrip.bodyMuted(color: mute),
            ),
          ],
          const SizedBox(height: TokensStrip.s3),
          progressBar,
        ],
      ),
    );

    return header;
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
  });

  final String title;
  final String icon;
  final bool completed;
  final String? description;
  final int? estimatedMinutes;
  final VoidCallback? onTap;
  final SetupStepCardVariant variant;
  final bool isLead;

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

    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dashboardReadableCaption(context, isDark: isDark);
    final doneColor =
        isDark
            ? TokensStrip.badgeSuccess.withValues(alpha: 0.92)
            : TokensStrip.badgeSuccess;
    final accent = completed ? doneColor : primary;
    final lead = isLead && !completed;

    return Semantics(
      button: !completed,
      enabled: !completed,
      label:
          completed
              ? '$title, concluído'
              : '$title, pendente, toque para abrir',
      child: Padding(
        padding: const EdgeInsets.only(bottom: TokensStrip.s3),
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
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
            child: Ink(
              decoration: fxStripCardDecoration(
                context,
                accent: accent,
                radius: TokensStrip.rCard,
                glowStrength: lead ? (isDark ? 0.18 : 0.22) : 0.05,
                emphasize: lead,
              ),
              padding: EdgeInsets.all(lead ? 14 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SetupStepIconBadge(
                    icon: icon,
                    completed: completed,
                    primary: primary,
                    doneColor: doneColor,
                    mute: mute,
                    size: lead ? 40 : 36,
                    iconSize: lead ? 19 : 17,
                    lead: lead,
                  ),
                  SizedBox(width: lead ? 12 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: dashboardCardTitleStyle(ink).copyWith(
                                  color: completed ? doneColor : ink,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: lead ? -0.15 : -0.1,
                                ),
                              ),
                            ),
                            if (lead) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primary.withValues(
                                    alpha: isDark ? 0.34 : 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'AGORA',
                                  style: dashboardChipLabelStyle(primary),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (description != null &&
                            description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description!,
                            maxLines: lead ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: dashboardCardSubtitleStyle(
                              context,
                              isDark: isDark,
                            ),
                          ),
                        ],
                        if (estimatedMinutes != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '~$estimatedMinutes min',
                            style: dashboardCardSubtitleStyle(
                              context,
                              isDark: isDark,
                            ).copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FxIcon(
                    name: completed ? 'circle-check' : 'chevron-right',
                    color:
                        completed
                            ? doneColor
                            : (lead
                                ? primary.withValues(alpha: 0.85)
                                : mute),
                    size: lead ? 20 : 18,
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
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkSoft;
    final doneColor =
        isDark
            ? TokensStrip.badgeSuccess.withValues(alpha: 0.85)
            : TokensStrip.badgeSuccess;

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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: TokensStrip.s2),
            child: Row(
              children: [
                _SetupStepIconBadge(
                  icon: icon,
                  completed: completed,
                  primary: primary,
                  doneColor: doneColor,
                  mute: mute,
                  size: 28,
                  iconSize: 16,
                ),
                const SizedBox(width: TokensStrip.s3),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: completed ? doneColor : ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!completed)
                  FxIcon(name: 'chevron-right', size: 14, color: mute),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupStepIconBadge extends StatelessWidget {
  const _SetupStepIconBadge({
    required this.icon,
    required this.completed,
    required this.primary,
    required this.doneColor,
    required this.mute,
    required this.size,
    required this.iconSize,
    this.lead = false,
  });

  final String icon;
  final bool completed;
  final Color primary;
  final Color doneColor;
  final Color mute;
  final double size;
  final double iconSize;
  final bool lead;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = completed ? doneColor : primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            completed
                ? TokensStrip.badgeSuccessBg
                : accent.withValues(alpha: isDark ? 0.26 : 0.14),
        borderRadius: BorderRadius.circular(TokensStrip.rInput),
        border: Border.all(
          color:
              completed
                  ? TokensStrip.badgeSuccess.withValues(alpha: 0.45)
                  : accent.withValues(alpha: isDark ? 0.38 : 0.22),
        ),
      ),
      child: Center(
        child:
            completed
                ? Icon(Icons.check_rounded, size: iconSize, color: doneColor)
                : FxIcon(
                  name: setupStepFxIconName(icon),
                  size: iconSize,
                  color: accent,
                  strokeWidth: lead ? 2.05 : 1.75,
                ),
      ),
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
            for (var i = 0; i < (compact ? 3 : 5); i++)
              Container(
                height: compact ? 44 : 88,
                margin: const EdgeInsets.only(bottom: TokensStrip.s3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(TokensStrip.rCard),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Entrada escalonada dos cards — respeita reduced motion.
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
    final success = TokensStrip.badgeSuccess;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return Semantics(
      liveRegion: true,
      label: 'Tudo configurado. Toque em Concluir setup.',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: TokensStrip.s3),
        padding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s4,
          vertical: TokensStrip.s3,
        ),
        decoration: BoxDecoration(
          color: success.withValues(alpha: isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          border: Border.all(color: success.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.celebration_rounded, color: success, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tudo configurado! Toque em Concluir setup.',
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Passos concluídos colapsados — reduz densidade no wizard.
class SetupCompletedStepsCollapse extends StatefulWidget {
  const SetupCompletedStepsCollapse({super.key, required this.titles});

  final List<String> titles;

  @override
  State<SetupCompletedStepsCollapse> createState() =>
      _SetupCompletedStepsCollapseState();
}

class _SetupCompletedStepsCollapseState
    extends State<SetupCompletedStepsCollapse> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.titles.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final doneColor =
        isDark
            ? TokensStrip.badgeSuccess.withValues(alpha: 0.92)
            : TokensStrip.badgeSuccess;

    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label:
                _expanded
                    ? 'Ocultar passos concluídos'
                    : '${widget.titles.length} passos concluídos, expandir',
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(TokensStrip.rInput),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: TokensStrip.s2,
                  horizontal: 4,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: doneColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.titles.length} passos concluídos',
                        style: TextStyle(
                          color: mute,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: mute,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 4),
            ...widget.titles.map(
              (title) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: TokensStrip.s2),
                child: Row(
                  children: [
                    Icon(Icons.check_rounded, size: 14, color: doneColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: doneColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SetupWizardCta extends StatelessWidget {
  const SetupWizardCta({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: FxLiquidPrimaryButton(
        label: label,
        onPressed:
            onPressed == null
                ? null
                : () {
                  HapticFeedback.mediumImpact();
                  onPressed!();
                },
      ),
    );
  }
}
