import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../notificacoes/widgets/notificacao_badge_button.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_screen_helpers.dart';
import 'dashboard_header_profile_avatar.dart';

/// Saudação + modo foco + chrome (tema, notificações, avatar).
class DashboardHomeHeader extends StatelessWidget {
  const DashboardHomeHeader({
    super.key,
    required this.nomePersonal,
    required this.logoUrl,
    required this.isDark,
    required this.primary,
    required this.focusMode,
    required this.onToggleFocus,
    required this.onProfileTap,
  });

  final String? nomePersonal;
  final String? logoUrl;
  final bool isDark;
  final Color primary;
  final bool focusMode;
  final VoidCallback onToggleFocus;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
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
                dashboardGreeting(nomePersonal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.35,
                  height: 1.15,
                  color: ink,
                ),
              ),
            ),
          ),
          SizedBox(width: DashboardLayout.headerIconGap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                button: true,
                toggled: focusMode,
                label:
                    focusMode
                        ? DashboardMicrocopy.modoFocoOn
                        : DashboardMicrocopy.modoFocoOff,
                child: IconButton(
                  tooltip: DashboardMicrocopy.modoFoco,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: DashboardLayout.touchTarget,
                    minHeight: DashboardLayout.touchTarget,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onToggleFocus,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) {
                      return ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      );
                    },
                    child: Icon(
                      focusMode ? Icons.bolt_rounded : Icons.bolt_outlined,
                      key: ValueKey(focusMode),
                      size: 22,
                      color: BrandPalette.sectionLink(primary, dark: isDark),
                    ),
                  ),
                ),
              ),
              SizedBox(width: DashboardLayout.headerIconGap),
              const ShellThemeToggle(size: DashboardLayout.touchTarget),
              SizedBox(width: DashboardLayout.headerIconGap),
              const NotificacaoBadgeButton(size: DashboardLayout.touchTarget),
              SizedBox(width: DashboardLayout.headerIconGap),
              DashboardHeaderProfileAvatar(
                primary: primary,
                isDark: isDark,
                photoUrl: logoUrl,
                initials: fxInitials(nomePersonal ?? 'F'),
                onTap: onProfileTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
