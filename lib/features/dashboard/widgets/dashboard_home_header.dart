import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../notificacoes/widgets/notificacao_badge_button.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_screen_helpers.dart';
import 'dashboard_header_profile_avatar.dart';

/// Saudação + chrome (tema, notificações, avatar).
/// Modo foco fica no banner “Foco do dia” — header sem crowding.
class DashboardHomeHeader extends StatelessWidget {
  const DashboardHomeHeader({
    super.key,
    required this.nomePersonal,
    required this.logoUrl,
    required this.isDark,
    required this.primary,
    required this.onProfileTap,
  });

  final String? nomePersonal;
  final String? logoUrl;
  final bool isDark;
  final Color primary;
  final VoidCallback onProfileTap;

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
        4,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      child: Row(
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
                style: AppTypography.inter(
                  fontSize: compact ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.35,
                  height: 1.15,
                  color: ink,
                ),
              ),
            ),
          ),
          SizedBox(width: chromeGap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShellThemeToggle(size: chromeSize),
              SizedBox(width: chromeGap),
              NotificacaoBadgeButton(size: chromeSize),
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
    );
  }
}
