part of 'perfil_screen.dart';

class _ProfileStat {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });
}

class _PlanPill extends StatelessWidget {
  final String label;

  const _PlanPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: EagleTokens.gold, size: 13),
          const SizedBox(width: 5),
          Text(
            'PLANO $label',
            style: const TextStyle(
              color: EagleTokens.gold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String semanticsLabel;

  const _HeroAction({
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(38),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String nome;
  final String? logoUrl;
  final Color primaryColor;
  final VoidCallback onTap;
  final bool loading;
  final String semanticsLabel;

  const _Avatar({
    required this.nome,
    required this.logoUrl,
    required this.primaryColor,
    required this.onTap,
    required this.loading,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      enabled: !loading,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 82,
            height: 82,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.92),
              boxShadow: const [
                BoxShadow(
                  color: EagleTokens.shadowSoft,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage:
                  logoUrl != null && logoUrl!.isNotEmpty
                      ? NetworkImage(logoUrl!)
                      : null,
              child:
                  logoUrl == null || logoUrl!.isEmpty
                      ? Text(
                        _initials(nome),
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      )
                      : null,
            ),
          ),
          Positioned(
            right: 1,
            bottom: 1,
            child: InkWell(
              onTap: loading ? null : onTap,
              borderRadius: BorderRadius.circular(26),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child:
                    loading
                        ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: FxLoading(strokeWidth: 2, color: Colors.white),
                        )
                        : const Icon(Icons.edit, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final bool isDark;
  final Color accent;
  final Color actionInk;
  final Widget child;

  const _CardSection({
    required this.title,
    required this.isDark,
    required this.child,
    this.subtitle,
    this.trailingLabel,
    this.onTrailingTap,
    required this.accent,
    required this.actionInk,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final a11yTitle = subtitle == null ? title : '$title. $subtitle';

    return Semantics(
      container: true,
      label: a11yTitle,
      child: Container(
        decoration: chrome.panel(radius: 16, accent: accent),
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: TokensStrip.s1),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: mute,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailingLabel != null && onTrailingTap != null)
                    Semantics(
                      button: true,
                      label: '$trailingLabel $title',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTrailingTap,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(
                                alpha: isDark ? 0.16 : 0.10,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  trailingLabel!,
                                  style: TextStyle(
                                    color: actionInk,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.north_east,
                                  size: 13,
                                  color: actionInk,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandPaletteStrip extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color mute;
  final bool usingDefault;

  const _BrandPaletteStrip({
    required this.primary,
    required this.secondary,
    required this.mute,
    required this.usingDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.palette_outlined, size: 14, color: mute),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            usingDefault
                ? 'Paleta padrão Focux · toque para personalizar'
                : 'Sua paleta está ativa · toque para editar',
            style: TextStyle(
              color: mute,
              fontSize: 11.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _PaletteDot(color: primary),
        const SizedBox(width: 6),
        _PaletteDot(color: secondary),
      ],
    );
  }
}

class _PaletteDot extends StatelessWidget {
  final Color color;

  const _PaletteDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}
