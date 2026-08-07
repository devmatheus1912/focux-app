part of 'perfil_screen.dart';

class _PerfilStickyBar extends StatelessWidget {
  const _PerfilStickyBar({
    required this.accent,
    required this.actionInk,
    required this.isDark,
  });

  final Color accent;
  final Color actionInk;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: chrome.sheetFill.withValues(alpha: isDark ? 0.96 : 0.98),
          border: Border(
            top: BorderSide(color: chrome.line.withValues(alpha: 0.7)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s4,
              10,
              TokensStrip.s4,
              12,
            ),
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Meus alunos',
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: actionInk,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          goPersonalShellTab(context, '/alunos');
                        },
                        icon: const Icon(Icons.groups_2_outlined, size: 18),
                        label: const Text('Meus alunos'),
                      ),
                    ),
                  ),
                  const SizedBox(width: TokensStrip.s3),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Copiloto IA',
                      child: FxLiquidPrimaryButton(
                        expand: true,
                        icon: Icons.auto_awesome_outlined,
                        label: 'Copiloto IA',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          goPersonalShellTab(context, '/ia/copiloto');
                        },
                      ),
                    ),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: compact ? 11 : 11.5,
                          height: 1.28,
                          fontWeight: FontWeight.w600,
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
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
    required this.onOpenEditor,
  });

  final String? slug;
  final Color accent;
  final Color actionInk;
  final Color mute;
  final bool isDark;
  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final normalizedSlug = slug?.trim();
    final hasSlug = normalizedSlug != null && normalizedSlug.isNotEmpty;

    if (!hasSlug) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: chrome.line),
          color: accent.withValues(alpha: isDark ? 0.08 : 0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sua vitrine online',
              style: TextStyle(
                color: ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: TokensStrip.s1),
            Text(
              'Crie o link público para divulgar no Instagram e WhatsApp.',
              style: TextStyle(color: mute, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: TokensStrip.s2),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onOpenEditor();
                },
                icon: const Icon(Icons.add_link_rounded, size: 18),
                label: const Text('Criar link público'),
              ),
            ),
          ],
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Link público',
                  style: TextStyle(
                    color: ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Personalizar página',
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onOpenEditor();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: actionInk,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(48, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Personalizar página'),
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s2),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: (isDark ? EagleTokens.darkCard : Colors.white).withValues(
                alpha: isDark ? 0.92 : 0.96,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.link_rounded, size: 18, color: actionInk),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Copiar link $displayLabel',
                  child: TextButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      copyLandingLink(
                        context,
                        url: copyUrl,
                        successMessage: 'Link copiado. Cole no Instagram ou WhatsApp.',
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: actionInk,
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copiar'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    openLandingLink(context, url: copyUrl);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: const Text('Ver ao vivo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: actionInk,
                    side: BorderSide(color: accent.withValues(alpha: 0.35)),
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: TokensStrip.s2),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    copyLandingLink(
                      context,
                      url: copyUrl,
                      successMessage:
                          'Link pronto para compartilhar no Instagram ou WhatsApp.',
                    );
                  },
                  icon: const Icon(Icons.ios_share_rounded, size: 17),
                  label: const Text('Compartilhar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
