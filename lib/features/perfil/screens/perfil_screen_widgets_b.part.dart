part of 'perfil_screen.dart';

class _HeroMarcaChip extends StatelessWidget {
  const _HeroMarcaChip({
    required this.score,
    required this.accent,
    required this.actionInk,
    required this.onTap,
    this.onShowHint,
  });

  final int score;
  final Color accent;
  final Color actionInk;
  final VoidCallback onTap;
  final VoidCallback? onShowHint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Marca $score por cento. Toque longo para ver como calculamos.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onShowHint,
          borderRadius: BorderRadius.circular(TokensStrip.rPill),
          child: Tooltip(
            message:
                'Como calculamos: foto, CREF, especialidade, bio, Instagram, paleta e PIX.',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(TokensStrip.rPill),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
              child: Text(
                'Marca $score%',
                style: TokensStrip.bodyMuted(color: actionInk).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanPill extends StatelessWidget {
  final String label;
  final Color accent;

  const _PlanPill({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: chrome.isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: EagleTokens.gold, size: 13),
          const SizedBox(width: 5),
          Text(
            'PLANO $label',
            style: TokensStrip.bodyMuted(color: EagleTokens.gold).copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
              fontSize: TokensStrip.fontBodySm - 2,
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
  final double size;

  const _HeroAction({
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final radius = size / 2;
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            width: size,
            height: size,
            decoration: chrome.headerAction(radius: radius),
            child: Icon(icon, color: chrome.ink, size: size * 0.48),
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
  final bool compact;
  final bool showEditBadge;

  const _Avatar({
    required this.nome,
    required this.logoUrl,
    required this.primaryColor,
    required this.onTap,
    required this.loading,
    required this.semanticsLabel,
    this.compact = false,
    this.showEditBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 46.0 : 82.0;
    final inner = size - 5;
    Widget avatarContent() {
      return Text(
        _initials(nome),
        style: TextStyle(
          fontSize:
              compact ? TokensStrip.fontH2 : TokensStrip.fontH1 - 5,
          fontWeight: FontWeight.w900,
          color: primaryColor,
        ),
      );
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      enabled: !loading,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: loading ? null : onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.92),
                  boxShadow: const [
                    BoxShadow(
                      color: EagleTokens.shadowSoft,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child:
                      logoUrl != null && logoUrl!.isNotEmpty
                          ? ClipOval(
                            child: Image.network(
                              logoUrl!,
                              width: inner,
                              height: inner,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => avatarContent(),
                            ),
                          )
                          : avatarContent(),
                ),
              ),
            ),
          ),
          if (showEditBadge)
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
                ? 'Paleta padrão · toque para personalizar'
                : 'Paleta ativa · toque para editar',
            style: TokensStrip.bodyMuted(color: mute).copyWith(
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

/// Ferramentas de QA — recolhidas, fora do fluxo do personal.
class _PerfilDebugTools extends StatelessWidget {
  const _PerfilDebugTools({
    required this.accent,
    required this.actionInk,
    required this.mute,
    required this.line,
  });

  final Color accent;
  final Color actionInk;
  final Color mute;
  final Color line;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chrome = ShellChrome.forDark(isDark);
    return Material(
      color: chrome.cardFill,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: chrome.line.withValues(alpha: 0.85)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s2,
          TokensStrip.s4,
          TokensStrip.s2,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            initiallyExpanded: false,
            iconColor: mute,
            collapsedIconColor: mute,
            title: Text(
              'Ferramentas de desenvolvimento',
              style: TokensStrip.bodyMuted(color: mute).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              'Só em debug — fora do fluxo do personal',
              style: TokensStrip.bodyMuted(
                color: mute.withValues(alpha: 0.85),
              ),
            ),
            children: [
              PerfilActionTile(
                icon: Icons.palette_outlined,
                label: 'TOKENS STRIP',
                value: 'Design system',
                accent: accent,
                actionInk: actionInk,
                mute: mute,
                line: line,
                onTap: () => context.go('/qa/tokens-strip'),
              ),
              PerfilActionTile(
                icon: Icons.science_outlined,
                label: 'QA Smoke Test',
                value: 'Smoke',
                accent: accent,
                actionInk: actionInk,
                mute: mute,
                line: line,
                showDivider: false,
                onTap: () => context.go('/qa/smoke'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
