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
          color: (isDark ? EagleTokens.darkCard : TokensStrip.cardBg)
              .withValues(alpha: 0.96),
          border: Border(top: BorderSide(color: chrome.line.withValues(alpha: 0.7))),
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
      child: Row(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
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
                    color: Color(0xFF6FE296),
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
        ],
      ),
    );
  }
}

