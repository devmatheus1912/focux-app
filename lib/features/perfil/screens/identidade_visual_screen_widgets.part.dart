part of 'identidade_visual_screen.dart';

class _LiveBrandHero extends StatelessWidget {
  const _LiveBrandHero({
    required this.primary,
    required this.secondary,
    required this.name,
    required this.slogan,
    required this.logoUrl,
    required this.paletteName,
    required this.reduceMotion,
  });

  final Color primary;
  final Color secondary;
  final String name;
  final String slogan;
  final String? logoUrl;
  final String paletteName;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final onHero = CuratedBrandPalette.readableOn(primary);
    final frost = onHero.withValues(alpha: 0.14);
    final frostBorder = onHero.withValues(alpha: 0.22);
    final mutedOnHero = onHero.withValues(alpha: 0.82);

    return AnimatedContainer(
      duration: identidadeHeroAnimDuration(reduceMotion: reduceMotion),
      curve: Curves.easeOutCubic,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandPalette.deep(primary),
            primary,
            BrandPalette.softened(secondary, amount: 0.12),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onHero.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -18,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondary.withValues(alpha: 0.22),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: frost,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: frostBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: EagleTokens.good,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Preview · $paletteName',
                            style: FocuxHubTypography.chip(
                              mutedOnHero,
                            ).copyWith(letterSpacing: 0.3),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: frost,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: frostBorder),
                      ),
                      child: Text(
                        identidadeAlunoVisibilityLabel(),
                        style: FocuxHubTypography.chip(
                          mutedOnHero,
                        ).copyWith(letterSpacing: 0.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s4),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: onHero.withValues(alpha: 0.16),
                      backgroundImage:
                          logoUrl != null && logoUrl!.isNotEmpty
                              ? NetworkImage(logoUrl!)
                              : null,
                      child:
                          logoUrl == null || logoUrl!.isEmpty
                              ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                style: FocuxTypography.headline(color: onHero),
                              )
                              : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : 'Seu app Focux',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FocuxHubTypography.pageTitle(
                              context,
                              color: onHero,
                            ).copyWith(letterSpacing: -0.5, height: 1),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            slogan.isNotEmpty
                                ? formatBrandSloganForDisplay(slogan)
                                : 'Slogan aparece aqui em tempo real',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: FocuxHubTypography.bodyMuted(
                              color: mutedOnHero,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoUploadRing extends StatelessWidget {
  const _LogoUploadRing({
    required this.nome,
    required this.logoUrl,
    required this.primary,
    required this.secondary,
    required this.uploading,
    this.onTap,
  });

  final String nome;
  final String? logoUrl;
  final Color primary;
  final Color secondary;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [primary, secondary, primary]),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.28),
                  blurRadius: 22,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ShellChrome.of(context).cardFill,
              border: Border.all(
                color: CuratedBrandPalette.readableOn(
                  primary,
                ).withValues(alpha: 0.65),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child:
                logoUrl != null && logoUrl!.isNotEmpty
                    ? Image.network(logoUrl!, fit: BoxFit.cover)
                    : Center(
                      child: Text(
                        nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                        style: FocuxTypography.display(
                          color: CuratedBrandPalette.chromeAccent(
                            primary,
                            secondary,
                            dark: ShellChrome.of(context).isDark,
                          ),
                        ).copyWith(fontSize: 36),
                      ),
                    ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: CuratedBrandPalette.readableOn(primary),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child:
                  uploading
                      ? Padding(
                        padding: const EdgeInsets.all(7),
                        child: FxLoading(
                          strokeWidth: 2,
                          color: CuratedBrandPalette.readableOn(primary),
                        ),
                      )
                      : Icon(
                        Icons.photo_camera_outlined,
                        size: 16,
                        color: CuratedBrandPalette.readableOn(primary),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CuratedPaletteGrid extends StatelessWidget {
  const _CuratedPaletteGrid({required this.selected, this.onSelect});

  final CuratedBrandPalette selected;
  final ValueChanged<CuratedBrandPalette>? onSelect;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemCount: CuratedBrandPalette.premium.length,
      itemBuilder: (context, index) {
        final palette = CuratedBrandPalette.premium[index];
        final isSelected = palette.id == selected.id;

        return Material(
          color: fxTransparent,
          child: InkWell(
            onTap: onSelect == null ? null : () => onSelect!(palette),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: chrome.cardFill,
                border: Border.all(
                  color:
                      isSelected
                          ? palette.chromeFor(dark: chrome.isDark)
                          : chrome.line.withValues(alpha: 0.9),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: palette.primary.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                        : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  BrandPalette.deep(palette.primary),
                                  palette.primary,
                                  palette.secondary,
                                ],
                                stops: const [0.0, 0.42, 1.0],
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    CuratedBrandPalette.readableOn(
                                      palette.primary,
                                    ).withValues(alpha: 0.14),
                                    fxTransparent,
                                    heroScrim(0.08),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: CuratedBrandPalette.readableOn(
                                    palette.primary,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: heroScrim(0.15),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: palette.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    palette.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.chip(
                      chrome.ink,
                    ).copyWith(letterSpacing: -0.2),
                  ),
                  Text(
                    palette.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      color: chrome.mute,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandField extends StatelessWidget {
  const _BrandField({
    required this.label,
    required this.controller,
    required this.accent,
    this.hint,
    this.icon,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final Color accent;
  final String? hint;
  final IconData? icon;
  final int? maxLength;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: FocuxHubTypography.chip(
            chrome.mute,
          ).copyWith(letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: chrome.cardFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: enabled ? 0.16 : 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            maxLength: maxLength,
            style: FocuxHubTypography.body(color: chrome.ink).copyWith(
              fontWeight: FontWeight.w600,
              height: maxLines > 1 ? 1.45 : 1.2,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: chrome.mute.withValues(alpha: 0.55),
                fontWeight: FontWeight.w500,
              ),
              prefixIcon:
                  icon != null
                      ? Icon(icon, size: 18, color: chrome.mute)
                      : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(
                icon != null ? 0 : 16,
                maxLines > 1 ? 14 : 15,
                16,
                maxLines > 1 ? 14 : 15,
              ),
              counterText: '',
            ),
            onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
          ),
        ),
        if (maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 2),
            child: Align(
              alignment: Alignment.centerRight,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  return Text(
                    '${controller.text.length}/$maxLength',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: chrome.mute.withValues(alpha: 0.75),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.mute,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: FocuxHubTypography.sectionTitle(
                  context,
                  color: ShellChrome.of(context).ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: mute, fontSize: 11.5, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaletteDarkPreview extends StatelessWidget {
  const _PaletteDarkPreview({required this.palette});

  final CuratedBrandPalette palette;

  @override
  Widget build(BuildContext context) {
    final accent = palette.chromeFor(dark: true);
    final onAccent = CuratedBrandPalette.readableOn(accent);
    return Semantics(
      label: identidadeDarkPreviewLabel(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EagleTokens.darkBg,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          border: Border.all(color: EagleTokens.darkLine),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                identidadeDarkPreviewLabel(),
                style: FocuxHubTypography.chip(
                  EagleTokens.darkInkMute,
                ).copyWith(letterSpacing: 0.2),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      size: 18,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ícones e botões',
                      style: FocuxHubTypography.bodyMuted(
                        color: EagleTokens.darkInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(TokensStrip.rButton),
                    ),
                    child: Text(
                      'Entrar',
                      style: FocuxHubTypography.chip(
                        onAccent,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaywallCard extends StatelessWidget {
  const _PaywallCard({required this.onTap, required this.chrome});

  final VoidCallback onTap;
  final ShellPalette chrome;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ShellSurface(
      accent: primary,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recurso Enterprise',
                style: FocuxHubTypography.cardTitle(color: chrome.ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Logo, slogan e paletas curadas para deixar seu app com cara de marca premium.',
            style: TextStyle(color: chrome.mute, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          FxLiquidPrimaryButton(label: 'Assinar Enterprise', onPressed: onTap),
        ],
      ),
    );
  }
}
