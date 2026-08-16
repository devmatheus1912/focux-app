import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../notificacoes/widgets/notificacao_badge_button.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_screen_helpers.dart';
import 'dashboard_header_profile_avatar.dart';

/// Header Home 10/10 — identidade limpa + chrome soft; «Foco» só no banner.
class DashboardHomeHeader extends StatelessWidget {
  const DashboardHomeHeader({
    super.key,
    required this.nomePersonal,
    required this.logoUrl,
    required this.isDark,
    required this.primary,
    required this.onProfileTap,
    this.notificacoesCountOverride,
    this.onQuickSearch,
    this.onHelp,
    this.freshnessLabel,
  });

  final String? nomePersonal;
  final String? logoUrl;
  final bool isDark;
  final Color primary;
  final VoidCallback onProfileTap;
  final int? notificacoesCountOverride;
  final VoidCallback? onQuickSearch;
  final VoidCallback? onHelp;
  final String? freshnessLabel;

  static const double _chrome = 36;
  static const double _chromeGap = 3;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dashboardReadableCaption(context, isDark: isDark);
    final firstName = dashboardPersonalFirstName(nomePersonal);
    final fullName = (nomePersonal ?? '').trim();
    final a11yName =
        fullName.isEmpty
            ? dashboardPersonalDisplayName(nomePersonal)
            : fxTitleCaseName(fullName);
    final width = MediaQuery.sizeOf(context).width;
    final compactChrome = DashboardLayout.isCompact(width);
    final freshness =
        (freshnessLabel != null && freshnessLabel!.isNotEmpty)
            ? freshnessLabel!
            : DashboardMicrocopy.painelAtualizado;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: DecoratedBox(
        decoration: fxStripCardDecoration(
          context,
          accent: primary,
          radius: TokensStrip.rCard,
          glowStrength: 0.04,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Semantics(
                button: true,
                label: '$a11yName. Abrir perfil',
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    DashboardHeaderProfileAvatar(
                      primary: primary,
                      isDark: isDark,
                      photoUrl: logoUrl,
                      initials: fxInitials(nomePersonal ?? 'F'),
                      size: 44,
                      onTap: onProfileTap,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark
                                    ? EagleTokens.darkCard
                                    : TokensStrip.cardBg,
                            width: 1.75,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Olá, $firstName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: dashboardPageTitleStyle(
                        context,
                        color: ink,
                      ).copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        freshness,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: dashboardCardSubtitleStyle(
                          context,
                          isDark: isDark,
                        ).copyWith(
                          color: mute,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              _HeaderChromeCluster(
                // <360: 3 ícones — busca cai (catálogo/tools cobrem).
                onQuickSearch: compactChrome ? null : onQuickSearch,
                onHelp: onHelp,
                notificacoesCountOverride: notificacoesCountOverride,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderChromeCluster extends StatelessWidget {
  const _HeaderChromeCluster({
    this.onQuickSearch,
    this.onHelp,
    this.notificacoesCountOverride,
  });

  final VoidCallback? onQuickSearch;
  final VoidCallback? onHelp;
  final int? notificacoesCountOverride;

  @override
  Widget build(BuildContext context) {
    const size = DashboardHomeHeader._chrome;
    const gap = DashboardHomeHeader._chromeGap;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onQuickSearch != null) ...[
          ShellHeaderIconButton(
            icon: 'search',
            size: size,
            tooltip: DashboardMicrocopy.buscaRapida,
            onTap: onQuickSearch!,
          ),
          const SizedBox(width: gap),
        ],
        if (onHelp != null) ...[
          ShellHeaderIconButton(
            icon: 'help',
            size: size,
            tooltip: DashboardMicrocopy.helpHomeOpen,
            onTap: onHelp!,
          ),
          const SizedBox(width: gap),
        ],
        const ShellThemeToggle(size: size),
        const SizedBox(width: gap),
        NotificacaoBadgeButton(
          size: size,
          countOverride: notificacoesCountOverride,
        ),
      ],
    );
  }
}
