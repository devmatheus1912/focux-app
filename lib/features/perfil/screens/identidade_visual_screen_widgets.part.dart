part of 'identidade_visual_screen.dart';

class _PaletteThemePreview extends StatelessWidget {
  const _PaletteThemePreview({
    required this.dark,
    required this.palette,
    required this.name,
    required this.slogan,
    required this.logoUrl,
    required this.reduceMotion,
  });

  final bool dark;
  final CuratedBrandPalette palette;
  final String name;
  final String slogan;
  final String? logoUrl;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final accent = palette.chromeFor(dark: dark);
    final onAccent = CuratedBrandPalette.readableOn(accent);
    final surface = dark ? context.tons.superficie : EagleTokens.card;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? context.tons.linha : EagleTokens.line;
    final label =
        dark ? identidadeDarkPreviewLabel() : identidadeLightPreviewLabel();
    final displayName = name.isNotEmpty ? name : 'Seu app Focux';
    final displaySlogan =
        slogan.isNotEmpty
            ? formatBrandSloganForDisplay(slogan)
            : 'Slogan aparece aqui em tempo real';

    return Semantics(
      label: label,
      child: AnimatedContainer(
        duration: identidadeHeroAnimDuration(reduceMotion: reduceMotion),
        curve: Curves.easeOutCubic,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          border: Border.all(color: line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.chip(
                  mute,
                ).copyWith(letterSpacing: 0.2),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: accent.withValues(alpha: 0.18),
                    backgroundImage:
                        logoUrl != null && logoUrl!.isNotEmpty
                            ? NetworkImage(logoUrl!)
                            : null,
                    child:
                        logoUrl == null || logoUrl!.isEmpty
                            ? Text(
                              displayName[0].toUpperCase(),
                              style: FocuxHubTypography.chip(
                                accent,
                              ).copyWith(fontWeight: FontWeight.w700),
                            )
                            : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.bodyMuted(
                        color: ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                displaySlogan,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(TokensStrip.rButton),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'Entrar',
                      style: FocuxHubTypography.chip(
                        onAccent,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
                    ? FxCachedNetworkImage(
                      imageUrl: logoUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                    )
                    : Center(
                      child: Text(
                        nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                        style: FocuxTypography.display(
                          color: CuratedBrandPalette.chromeAccent(
                            primary,
                            secondary,
                            dark: ShellChrome.of(context).isDark,
                          ),
                        ).copyWith(fontSize: TokensStrip.fontDestaque),
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
                        FxIcons.cameraPequeno,
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
    this.avisoDepoisDe,
  });

  /// Passando de tantos caracteres, avisa que pode aparecer cortado.
  final int? avisoDepoisDe;

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
            // Slogan salvo mais longo continua inteiro no campo.
            maxLength: null,
            style: FocuxHubTypography.body(color: chrome.ink).copyWith(
              fontWeight: FontWeight.w600,
              height: maxLines > 1 ? 1.45 : 1.2,
            ),
            decoration: InputDecoration(
              filled: false,
              hintText: hint,
              hintStyle: TextStyle(
                color: chrome.mute.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
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
                  final n = controller.text.length;
                  final passou = n > maxLength!;
                  final aviso = avisoDepoisDe;
                  final alerta =
                      chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn;
                  return Row(
                    children: [
                      if (aviso != null && n > aviso)
                        Expanded(
                          child: Text(
                            passou
                                ? 'Encurte para até $maxLength caracteres.'
                                : 'Pode aparecer cortado no celular do aluno.',
                            style: FocuxHubTypography.chip(
                              passou ? EagleTokens.bad : alerta,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      Text(
                        '$n/$maxLength',
                        style: FocuxHubTypography.chip(
                          passou ? EagleTokens.bad : chrome.mute,
                        ),
                      ),
                    ],
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
  const _PanelTitle({required this.title, required this.mute});

  final String title;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: FocuxHubTypography.sectionTitle(
          context,
          color: ShellChrome.of(context).ink,
        ),
      ),
    );
  }
}

/// Faixa presa no topo quando a prévia sai da tela: cores e estilo à vista,
/// toque volta para a prévia.
class _FaixaDaPrevia extends StatelessWidget {
  const _FaixaDaPrevia({
    required this.palette,
    required this.estilo,
    required this.onTap,
  });

  final CuratedBrandPalette palette;
  final String estilo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    Widget bolinha(Color cor) => Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: cor,
        shape: BoxShape.circle,
        border: Border.all(color: chrome.ink.withValues(alpha: 0.12)),
      ),
    );
    return Semantics(
      button: true,
      label: 'Prévia: $estilo. Toque para ver.',
      excludeSemantics: true,
      child: ShellSurface(
        accent: palette.chromeFor(dark: chrome.isDark),
        blur: true,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s3,
          vertical: TokensStrip.s2,
        ),
        child: Row(
          children: [
            bolinha(palette.primary),
            const SizedBox(width: 4),
            bolinha(palette.secondary),
            const SizedBox(width: TokensStrip.s2),
            Expanded(
              child: Text(
                'Prévia · $estilo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.rotulo(color: chrome.ink),
              ),
            ),
            Icon(FxIcons.chevronCima, size: 18, color: chrome.mute),
          ],
        ),
      ),
    );
  }
}
