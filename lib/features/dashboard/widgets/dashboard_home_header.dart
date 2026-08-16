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

/// Uma composição: avatar + nome/freshness | chrome (sem linha órfã de ícones).
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
    // Compacto um pouco menor: libera largura pro nome composto sem 2ª faixa.
    final chromeSize = width < 430 ? 40.0 : DashboardLayout.headerActionSize(width);
    final chromeGap = width < 430 ? 4.0 : DashboardLayout.headerChromeGap(
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
        8,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DashboardHeaderProfileAvatar(
            primary: primary,
            isDark: isDark,
            photoUrl: logoUrl,
            initials: fxInitials(nomePersonal ?? 'F'),
            size: chromeSize + 4,
            onTap: onProfileTap,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  button: true,
                  label: '$a11yName. Abrir perfil',
                  child: GestureDetector(
                    onTap: onProfileTap,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      displayName,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: dashboardPageTitleStyle(context, color: ink)
                          .copyWith(
                            fontSize: compact ? 18 : 20,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                if (freshnessLabel != null && freshnessLabel!.isNotEmpty) ...[
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
                      ).copyWith(color: mute, fontSize: 12, height: 1.2),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
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
    );
  }
}
