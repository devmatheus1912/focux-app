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

/// Header Home — uma superfície, chrome soft (Linear). Modo foco só no Foco do dia.
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
    final compact = DashboardLayout.isCompact(width);
    final chromeSize = DashboardLayout.headerActionSize(width).clamp(36.0, 42.0);
    final chromeGap = compact ? 4.0 : 6.0;

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
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
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
                      size: 46,
                      onTap: onProfileTap,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark
                                    ? EagleTokens.darkCard
                                    : TokensStrip.cardBg,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.35),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
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
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        style: dashboardCardSubtitleStyle(
                          context,
                          isDark: isDark,
                        ).copyWith(color: mute, height: 1.25),
                        children: [
                          const TextSpan(
                            text: DashboardMicrocopy.headerTaglineLead,
                          ),
                          TextSpan(
                            text: DashboardMicrocopy.headerTaglineAccent,
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(
                            text: DashboardMicrocopy.headerTaglineTail,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (freshnessLabel != null &&
                        freshnessLabel!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          freshnessLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: dashboardCardSubtitleStyle(
                            context,
                            isDark: isDark,
                          ).copyWith(
                            color: mute.withValues(alpha: 0.78),
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _HeaderChromeCluster(
                chromeSize: chromeSize,
                chromeGap: chromeGap,
                onQuickSearch: onQuickSearch,
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

/// Chrome do shell — mesma linguagem dos cards (sem rail escuro).
class _HeaderChromeCluster extends StatelessWidget {
  const _HeaderChromeCluster({
    required this.chromeSize,
    required this.chromeGap,
    this.onQuickSearch,
    this.onHelp,
    this.notificacoesCountOverride,
  });

  final double chromeSize;
  final double chromeGap;
  final VoidCallback? onQuickSearch;
  final VoidCallback? onHelp;
  final int? notificacoesCountOverride;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onQuickSearch != null) ...[
          ShellHeaderIconButton(
            icon: 'search',
            size: chromeSize,
            tooltip: DashboardMicrocopy.buscaRapida,
            onTap: onQuickSearch!,
          ),
          SizedBox(width: chromeGap),
        ],
        if (onHelp != null) ...[
          ShellHeaderIconButton(
            icon: 'help',
            size: chromeSize,
            tooltip: DashboardMicrocopy.helpHomeOpen,
            onTap: onHelp!,
          ),
          SizedBox(width: chromeGap),
        ],
        ShellThemeToggle(size: chromeSize),
        SizedBox(width: chromeGap),
        NotificacaoBadgeButton(
          size: chromeSize,
          countOverride: notificacoesCountOverride,
        ),
      ],
    );
  }
}
