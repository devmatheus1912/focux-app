import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../notificacoes/widgets/notificacao_badge_button.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_screen_helpers.dart';
import 'dashboard_header_profile_avatar.dart';

/// Saudação + chrome (tema, busca, IA, notificações, avatar).
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
    this.onIaTeaser,
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
  final VoidCallback? onIaTeaser;
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        6,
        TokensStrip.s4,
        TokensStrip.s2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    dashboardGreeting(nomePersonal, compact: compact),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: dashboardPageTitleStyle(context, color: ink),
                  ),
                ),
              ),
              SizedBox(width: chromeGap),
              Row(
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
                  if (onIaTeaser != null) ...[
                    Tooltip(
                      message: DashboardMicrocopy.sugestaoIaDisclaimer,
                      child: ShellHeaderIconButton(
                        icon: 'spark',
                        size: chromeSize,
                        tooltip: DashboardMicrocopy.sugestaoIa,
                        onTap: onIaTeaser!,
                      ),
                    ),
                    SizedBox(width: chromeGap),
                  ],
                  ShellThemeToggle(size: chromeSize),
                  SizedBox(width: chromeGap),
                  NotificacaoBadgeButton(
                    size: chromeSize,
                    countOverride: notificacoesCountOverride,
                  ),
                  SizedBox(width: chromeGap),
                  DashboardHeaderProfileAvatar(
                    primary: primary,
                    isDark: isDark,
                    photoUrl: logoUrl,
                    initials: fxInitials(nomePersonal ?? 'F'),
                    size: chromeSize,
                    onTap: onProfileTap,
                  ),
                ],
              ),
            ],
          ),
          if (freshnessLabel != null && freshnessLabel!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Semantics(
              liveRegion: true,
              child: Text(
                freshnessLabel!,
                style: FocuxHubTypography.bodyMuted(
                  color: dashboardReadableCaption(context, isDark: isDark),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
