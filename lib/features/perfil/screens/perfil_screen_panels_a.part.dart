part of 'perfil_screen.dart';

class _BrandPreview extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final String profileName;
  final String subtitle;
  final String? logoUrl;
  final bool isDark;
  final bool compact;

  const _BrandPreview({
    required this.primary,
    required this.secondary,
    required this.profileName,
    required this.subtitle,
    this.logoUrl,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 40.0 : 50.0;
    final pad = compact ? 12.0 : 15.0;
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ),
        boxShadow:
            compact
                ? null
                : [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                    spreadRadius: -6,
                  ),
                ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(compact ? 12 : 15),
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    logoUrl != null && logoUrl!.isNotEmpty
                        ? Image.network(
                          logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Icon(
                                Icons.fitness_center,
                                color: primary,
                                size: compact ? 18 : 22,
                              ),
                        )
                        : Icon(
                          Icons.fitness_center,
                          color: primary,
                          size: compact ? 18 : 22,
                        ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 52),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TokensStrip.body(color: Colors.white).copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize:
                              compact
                                  ? TokensStrip.fontBodySm + 1
                                  : TokensStrip.fontBody,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TokensStrip.bodyMuted(
                          color: Colors.white.withValues(alpha: 0.88),
                        ).copyWith(
                          height: 1.28,
                          fontWeight: FontWeight.w600,
                          fontSize:
                              compact
                                  ? TokensStrip.fontBodySm - 2
                                  : TokensStrip.fontBodySm - 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(TokensStrip.rPill),
                border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
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
                  const SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: TokensStrip.fontBodySm - 3,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloco share-first da vitrine (dentro de Marca e vitrine).
class _PerfilPublicLinkCard extends StatelessWidget {
  const _PerfilPublicLinkCard({
    required this.slug,
    required this.accent,
    required this.actionInk,
    required this.mute,
    required this.isDark,
    required this.profileComplete,
    required this.onOpenEditor,
  });

  final String? slug;
  final Color accent;
  final Color actionInk;
  final Color mute;
  final bool isDark;
  final bool profileComplete;
  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final normalizedSlug = slug?.trim();
    final hasSlug = normalizedSlug != null && normalizedSlug.isNotEmpty;

    if (!hasSlug) {
      return Semantics(
        button: true,
        label: 'Criar link público da vitrine',
        child: TextButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            onOpenEditor();
          },
          icon: const Icon(Icons.add_link_rounded, size: 18),
          label: const Text('Criar link público'),
        ),
      );
    }

    final displayLabel = Env.landingPageDisplayLabel(normalizedSlug);
    final copyUrl = Env.landingPageUrl(normalizedSlug);

    return Semantics(
      container: true,
      label: 'Sua vitrine online. Link $displayLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color:
                  profileComplete
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : accent.withValues(alpha: 0.05))
                      : (isDark
                          ? EagleTokens.darkCard
                          : Colors.white).withValues(
                        alpha: isDark ? 0.72 : 0.92,
                      ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    profileComplete
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : accent.withValues(alpha: 0.1))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : accent.withValues(alpha: 0.14)),
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(Icons.link_rounded, size: 18, color: actionInk),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TokensStrip.body(color: ink).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: TokensStrip.fontBodySm + 0.5,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Copiar link $displayLabel',
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      copyLandingLink(
                        context,
                        url: copyUrl,
                        successMessage:
                            'Link copiado. Cole no Instagram ou WhatsApp.',
                        reserveBottom: 96,
                      );
                    },
                    tooltip: 'Copiar link',
                    icon: Icon(Icons.copy_rounded, size: 18, color: actionInk),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (profileComplete) ...[
            const SizedBox(height: TokensStrip.s2),
            _PerfilVitrineQuietActions(
              mute: mute,
              actionInk: actionInk,
              copyUrl: copyUrl,
              onOpenEditor: onOpenEditor,
              includeShare: true,
            ),
          ] else ...[
            const SizedBox(height: TokensStrip.s3),
            Semantics(
              button: true,
              label: 'Compartilhar link da vitrine',
              child: FxLiquidPrimaryButton(
                icon: Icons.ios_share_rounded,
                label: 'Compartilhar',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  unawaited(
                    AnalyticsService.instance.track(
                      ProductEvents.perfilShareTapped,
                    ),
                  );
                  copyLandingLink(
                    context,
                    url: copyUrl,
                    successMessage:
                        'Link pronto para compartilhar no Instagram ou WhatsApp.',
                    reserveBottom: 96,
                  );
                },
              ),
            ),
            const SizedBox(height: TokensStrip.s2),
            _PerfilVitrineQuietActions(
              mute: mute,
              actionInk: actionInk,
              copyUrl: copyUrl,
              onOpenEditor: onOpenEditor,
              includeShare: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _PerfilVitrineQuietActions extends StatelessWidget {
  const _PerfilVitrineQuietActions({
    required this.mute,
    required this.actionInk,
    required this.copyUrl,
    required this.onOpenEditor,
    this.includeShare = true,
  });

  final Color mute;
  final Color actionInk;
  final String copyUrl;
  final VoidCallback onOpenEditor;
  final bool includeShare;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: includeShare ? WrapAlignment.start : WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 0,
      children: [
        if (includeShare) ...[
          Semantics(
            button: true,
            label: 'Compartilhar link da vitrine',
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                unawaited(
                  AnalyticsService.instance.track(
                    ProductEvents.perfilShareTapped,
                  ),
                );
                copyLandingLink(
                  context,
                  url: copyUrl,
                  successMessage:
                      'Link pronto para compartilhar no Instagram ou WhatsApp.',
                  reserveBottom: 96,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: actionInk,
                minimumSize: const Size(48, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: Icon(Icons.ios_share_rounded, size: 16, color: actionInk),
              label: const Text('Compartilhar'),
            ),
          ),
          Text(
            '·',
            style: TokensStrip.bodyMuted(color: mute).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        Semantics(
          button: true,
          label: 'Ver vitrine ao vivo',
          child: TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              openLandingLink(context, url: copyUrl);
            },
            style: TextButton.styleFrom(
              foregroundColor: mute,
              minimumSize: const Size(48, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Ver ao vivo'),
          ),
        ),
        Text(
          '·',
          style: TokensStrip.bodyMuted(color: mute).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Semantics(
          button: true,
          label: 'Personalizar página da vitrine',
          child: TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              onOpenEditor();
            },
            style: TextButton.styleFrom(
              foregroundColor: mute,
              minimumSize: const Size(48, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Personalizar'),
          ),
        ),
      ],
    );
  }
}

