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

/// Mesmo ritmo do Foco do dia: card strip + identidade em cima + chrome embaixo.
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
    final width = MediaQuery.sizeOf(context).width;
    final compact = DashboardLayout.isCompact(width);
    final chromeSize = DashboardLayout.headerActionSize(width);
    final chromeGap = DashboardLayout.headerChromeGap(
      focusMode: compact,
      compact: compact,
    );
    final mute = dashboardReadableCaption(context, isDark: isDark);
    final displayName = dashboardPersonalDisplayName(nomePersonal);
    final fullName = (nomePersonal ?? '').trim();
    final a11yName = fullName.isEmpty ? displayName : fxTitleCaseName(fullName);

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
          glowStrength: 0.05,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                button: true,
                label: '$a11yName. Abrir perfil',
                child: InkWell(
                  onTap: onProfileTap,
                  borderRadius: BorderRadius.circular(TokensStrip.rInput),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DashboardHeaderProfileAvatar(
                        primary: primary,
                        isDark: isDark,
                        photoUrl: logoUrl,
                        initials: fxInitials(nomePersonal ?? 'F'),
                        size: 44,
                        onTap: onProfileTap,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: dashboardCardTitleStyle(ink).copyWith(
                                fontSize: compact ? 17 : 18,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
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
                                    color: mute,
                                    fontSize: 12,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
