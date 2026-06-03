part of 'dashboard_command_center_section.dart';

class CommandActionItem {
  final String icon;
  final String title;
  final String subtitle;
  final String route;
  final CommandActionTone tone;

  const CommandActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.tone,
  });
}

class CommandActionPanel extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final bool loading;
  final bool unavailable;
  final List<CommandActionItem> actions;

  const CommandActionPanel({
    super.key,
    required this.isDark,
    required this.primary,
    required this.loading,
    this.unavailable = false,
    required this.actions,
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
              'Próximas ações',
              style: TokensStrip.h2(
                color: heading,
                fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
              ).copyWith(fontSize: 15),
            ),
            const Spacer(),
            Text(
              'Impacto hoje',
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
          CommandLoadingTile(
            isDark: isDark,
            primary: primary,
            title: 'Central temporariamente indisponível',
            subtitle: 'Puxe para atualizar ou tente em instantes.',
          )
        else if (actions.isEmpty)
          CommandLoadingTile(
            isDark: isDark,
            primary: primary,
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

class CommandLoadingTile extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final String title;
  final String subtitle;

  const CommandLoadingTile({
    super.key,
    required this.isDark,
    required this.primary,
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
          Shimmer.fromColors(
            baseColor: primary.withValues(alpha: isDark ? 0.18 : 0.10),
            highlightColor: primary.withValues(alpha: isDark ? 0.32 : 0.18),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.24 : 0.14),
                borderRadius: BorderRadius.circular(15),
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
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final accent = commandToneAccent(item.tone, primary);
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
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
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
