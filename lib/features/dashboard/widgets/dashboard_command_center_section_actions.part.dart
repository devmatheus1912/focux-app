part of 'dashboard_command_center_section.dart';

class CommandActionPanel extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final bool loading;
  final bool unavailable;
  final List<CommandActionItem> actions;
  final String? prioritiesActionLabel;
  final VoidCallback? onPrioritiesTap;

  const CommandActionPanel({
    super.key,
    required this.isDark,
    required this.primary,
    required this.loading,
    this.unavailable = false,
    required this.actions,
    this.prioritiesActionLabel,
    this.onPrioritiesTap,
  });

  @override
  Widget build(BuildContext context) {
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final rowAccent = BrandPalette.sectionAccent(primary, dark: isDark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FxIcon(name: 'route', size: 17, color: rowAccent),
            const SizedBox(width: 8),
            Text(
              DashboardMicrocopy.proximasAcoes,
              style: TokensStrip.h2(
                color: heading,
                fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
              ).copyWith(fontSize: 15),
            ),
            const Spacer(),
            if (prioritiesActionLabel != null && onPrioritiesTap != null)
              Semantics(
                button: true,
                label: prioritiesActionLabel,
                child: TextButton(
                  onPressed: loading ? null : onPrioritiesTap,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: BrandPalette.sectionLink(
                      primary,
                      dark: isDark,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    prioritiesActionLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              )
            else
              Text(
                DashboardMicrocopy.impactoHoje,
                style: TextStyle(
                  color: BrandPalette.sectionLink(primary, dark: isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(
          color:
              isDark
                  ? EagleTokens.glassBorder
                  : TokensStrip.borderDefault.withValues(alpha: 0.85),
          height: 1,
        ),
        const SizedBox(height: 12),
        if (loading)
          CommandActionsShimmer(isDark: isDark, primary: primary)
        else if (unavailable)
          CommandStatusTile(
            isDark: isDark,
            primary: primary,
            icon: Icons.cloud_off_rounded,
            title: 'Central temporariamente indisponível',
            subtitle: 'Puxe para atualizar ou tente em instantes.',
          )
        else if (actions.isEmpty)
          CommandStatusTile(
            isDark: isDark,
            primary: primary,
            icon: Icons.check_circle_outline_rounded,
            title: 'Operação sob controle',
            subtitle: 'Nenhuma ação crítica para agora.',
          )
        else
          for (var index = 0; index < actions.length; index++) ...[
            CommandActionTile(
              item: actions[index],
              isDark: isDark,
              primary: primary,
            ),
            if (index < actions.length - 1) ...[
              const SizedBox(height: 10),
              Divider(
                color:
                    isDark
                        ? EagleTokens.glassBorder.withValues(alpha: 0.65)
                        : TokensStrip.borderDefault.withValues(alpha: 0.75),
                height: 1,
              ),
              const SizedBox(height: 10),
            ],
          ],
      ],
    );
  }
}

class CommandActionsShimmer extends StatelessWidget {
  const CommandActionsShimmer({
    super.key,
    required this.isDark,
    required this.primary,
  });

  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(2, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index == 0 ? 10 : 0),
          child: Shimmer.fromColors(
            baseColor: primary.withValues(alpha: isDark ? 0.18 : 0.10),
            highlightColor: primary.withValues(alpha: isDark ? 0.32 : 0.18),
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.24 : 0.14),
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Empty / unavailable — static icon (sem shimmer de loading).
class CommandStatusTile extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final IconData icon;
  final String title;
  final String subtitle;

  const CommandStatusTile({
    super.key,
    required this.isDark,
    required this.primary,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final chrome = ShellChrome.forDark(isDark);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: chrome.panel(radius: TokensStrip.rCard, accent: primary),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 20, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: mute, fontSize: 11.6, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommandActionTile extends StatelessWidget {
  final CommandActionItem item;
  final bool isDark;
  final Color primary;
  final VoidCallback? onTap;

  const CommandActionTile({
    super.key,
    required this.item,
    required this.isDark,
    required this.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dashboardReadableCaption(context, isDark: isDark);
    final accent = commandToneAccent(item.tone, primary);
    final badge = item.priorityBadge;
    return Semantics(
      label: '${item.title}. ${item.subtitle}',
      button: true,
      child: InkWell(
        onTap: onTap ?? () => context.go(item.route),
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: AnimatedScale(
          scale: 1,
          duration: dashboardMotionDuration(
            context,
            normal: const Duration(milliseconds: 110),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: fxStripCardDecoration(
              context,
              accent: accent,
              radius: TokensStrip.rCard,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.24 : 0.14),
                    borderRadius: BorderRadius.circular(TokensStrip.rInput),
                  ),
                  child: Center(
                    child: FxIcon(name: item.icon, color: accent, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ink,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (badge != null && badge.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Builder(
                              builder: (context) {
                                final badgeColors =
                                    dashboardPriorityBadgeColors(
                                      isDark: isDark,
                                      accent: accent,
                                    );
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColors.background,
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        isDark
                                            ? Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.12,
                                              ),
                                            )
                                            : null,
                                  ),
                                  child: Text(
                                    badge,
                                    style: TextStyle(
                                      color: badgeColors.foreground,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mute,
                          fontSize: 11.6,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FxIcon(name: 'chevron-right', color: mute, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CommandPrioritiesSheet extends StatefulWidget {
  const CommandPrioritiesSheet({
    super.key,
    required this.parentContext,
    required this.sheetContext,
    required this.isDark,
    required this.primary,
    required this.actions,
  });

  final BuildContext parentContext;
  final BuildContext sheetContext;
  final bool isDark;
  final Color primary;
  final List<CommandActionItem> actions;

  @override
  State<CommandPrioritiesSheet> createState() => _CommandPrioritiesSheetState();
}

class _CommandPrioritiesSheetState extends State<CommandPrioritiesSheet> {
  late bool _radarExpanded;

  @override
  void initState() {
    super.initState();
    final radarCount =
        widget.actions.where((action) => action.isRadarStudent).length;
    _radarExpanded = radarCount <= 2;
  }

  void _openAction(CommandActionItem item) {
    Navigator.of(widget.sheetContext).pop();
    widget.parentContext.go(item.route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primary = widget.primary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final mute = dashboardReadableCaption(widget.sheetContext, isDark: isDark);
    final heading = BrandPalette.sectionHeading(primary, dark: isDark);
    final link = BrandPalette.sectionLink(primary, dark: isDark);
    final impactActions =
        widget.actions.where((action) => !action.isRadarStudent).toList();
    final radarActions =
        widget.actions.where((action) => action.isRadarStudent).toList();
    final media = MediaQuery.of(widget.sheetContext);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        math.max(12, media.viewPadding.bottom + 10),
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.72),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: fxStripCardDecoration(
          widget.sheetContext,
          radius: 28,
          glowStrength: isDark ? 0.28 : 0.48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: line.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: BrandPalette.soft(primary, dark: isDark),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: FxIcon(name: 'route', size: 18, color: primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Todas as prioridades',
                        style: TokensStrip.h2(
                          color: primary,
                          fontFamily:
                              Theme.of(
                                widget.sheetContext,
                              ).textTheme.bodyLarge?.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ordenadas pelo impacto de hoje.',
                        style: TokensStrip.bodyMuted(
                          color: mute,
                          fontFamily:
                              Theme.of(
                                widget.sheetContext,
                              ).textTheme.bodyLarge?.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(widget.sheetContext).pop(),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 18, color: mute),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                children: [
                  for (
                    var index = 0;
                    index < impactActions.length;
                    index++
                  ) ...[
                    if (index > 0) const SizedBox(height: 8),
                    CommandActionTile(
                      item: impactActions[index],
                      isDark: isDark,
                      primary: primary,
                      onTap: () => _openAction(impactActions[index]),
                    ),
                  ],
                  if (radarActions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      button: true,
                      expanded: _radarExpanded,
                      label:
                          'Ações por aluno, ${radarActions.length} itens. '
                          '${_radarExpanded ? 'Expandido' : 'Recolhido'}',
                      child: InkWell(
                        onTap: () {
                          dashboardHapticCollapseToggle();
                          setState(() => _radarExpanded = !_radarExpanded);
                        },
                        borderRadius: BorderRadius.circular(TokensStrip.rInput),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Ações por aluno (${radarActions.length})',
                                  style: AppTypography.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: heading,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: _radarExpanded ? 0.25 : 0,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 22,
                                  color: link,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_radarExpanded) ...[
                      const SizedBox(height: 8),
                      for (
                        var index = 0;
                        index < radarActions.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(height: 8),
                        CommandActionTile(
                          item: radarActions[index],
                          isDark: isDark,
                          primary: primary,
                          onTap: () => _openAction(radarActions[index]),
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
