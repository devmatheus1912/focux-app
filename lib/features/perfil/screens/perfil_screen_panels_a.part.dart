part of 'perfil_screen.dart';

/// Entrada suave do conteúdo do perfil (respeita reduce-motion).
class _PerfilContentEntrance extends StatelessWidget {
  const _PerfilContentEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (TokensStrip.prefersReducedMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

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
          color: (isDark ? EagleTokens.darkCard : TokensStrip.cardBg)
              .withValues(alpha: 0.96),
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
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        child: SafeArea(
          top: false,
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
                const SizedBox(width: 10),
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
    );
  }
}

class _PerfilBottomActions extends StatelessWidget {
  final bool profileComplete;
  final bool walletComplete;
  final PerfilNextStep primaryCta;
  final void Function(PerfilChecklistAction action) onChecklistAction;

  const _PerfilBottomActions({
    required this.profileComplete,
    required this.walletComplete,
    required this.primaryCta,
    required this.onChecklistAction,
  });

  @override
  Widget build(BuildContext context) {
    if (profileComplete) {
      return const SizedBox.shrink();
    }

    if (!walletComplete) {
      return SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.push('/perfil/wallet');
                },
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Configurar PIX'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FxLiquidPrimaryButton(
                expand: true,
                icon:
                    primaryCta.action == PerfilChecklistAction.convites
                        ? Icons.person_add_outlined
                        : Icons.arrow_forward_rounded,
                label: primaryCta.buttonLabel,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onChecklistAction(primaryCta.action);
                },
              ),
            ),
          ],
        ),
      );
    }

    return FxLiquidPrimaryButton(
      icon:
          primaryCta.action == PerfilChecklistAction.convites
              ? Icons.person_add_outlined
              : Icons.arrow_forward_rounded,
      label: primaryCta.buttonLabel,
      onPressed: () {
        HapticFeedback.selectionClick();
        onChecklistAction(primaryCta.action);
      },
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

  const _BrandPreview({
    required this.primary,
    required this.secondary,
    required this.profileName,
    required this.subtitle,
    this.logoUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ),
        boxShadow: [
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                                size: 22,
                              ),
                        )
                        : Icon(Icons.fitness_center, color: primary, size: 22),
              ),
              const SizedBox(width: 12),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 11.5,
                          height: 1.3,
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
                borderRadius: BorderRadius.circular(999),
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
                letterSpacing: -0.15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Defina seu link público para compartilhar no Instagram e WhatsApp.',
              style: TextStyle(color: mute, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 10),
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: isDark ? 0.14 : 0.07),
              accent.withValues(alpha: isDark ? 0.06 : 0.03),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sua vitrine online',
                        style: TextStyle(
                          color: ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Compartilhe no Instagram, WhatsApp e bio.',
                        style: TextStyle(
                          color: mute,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Personalizar landing',
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onOpenEditor();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: actionInk,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(48, 36),
                    ),
                    child: const Text('Personalizar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: (isDark ? EagleTokens.darkCard : Colors.white)
                    .withValues(alpha: isDark ? 0.92 : 0.96),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.16)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.link_rounded, size: 16, color: actionInk),
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
                    child: IconButton(
                      tooltip: 'Copiar link',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        copyLandingLink(
                          context,
                          url: copyUrl,
                          successMessage: 'Link copiado para compartilhar.',
                        );
                      },
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: actionInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
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
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      copyLandingLink(
                        context,
                        url: copyUrl,
                        successMessage: 'Link copiado para compartilhar.',
                      );
                    },
                    icon: const Icon(Icons.ios_share_rounded, size: 17),
                    label: const Text('Compartilhar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
