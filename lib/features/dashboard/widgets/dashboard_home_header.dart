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
    final width = MediaQuery.sizeOf(context).width;
    final compact = DashboardLayout.isCompact(width);
    final showFocusLabel = focusMode && width >= 360;
    final chromeGap = DashboardLayout.headerChromeGap(
      focusMode: focusMode,
      compact: compact,
    );
    final link = BrandPalette.sectionLink(primary, dark: isDark);
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
              Semantics(
                button: true,
                toggled: focusMode,
                label:
                    focusMode
                        ? DashboardMicrocopy.modoFocoOn
                        : DashboardMicrocopy.modoFocoOff,
                child: Tooltip(
                  message: DashboardMicrocopy.modoFoco,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onToggleFocus,
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        constraints: const BoxConstraints(
                          minWidth: DashboardLayout.touchTarget,
                          minHeight: DashboardLayout.touchTarget,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: showFocusLabel ? 8 : 6,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              focusMode
                                  ? BrandPalette.soft(
                                    primary,
                                    dark: isDark,
                                  ).withValues(alpha: isDark ? 0.55 : 0.9)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border:
                              focusMode
                                  ? Border.all(
                                    color: primary.withValues(alpha: 0.45),
                                  )
                                  : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              focusMode
                                  ? Icons.bolt_rounded
                                  : Icons.bolt_outlined,
                              size: 20,
                              color: link,
                            ),
                            if (showFocusLabel) ...[
                              const SizedBox(width: 4),
                              Text(
                                'Foco',
                                style: AppTypography.inter(
                                  fontSize: TokensStrip.fontBodySm,
                                  fontWeight: FontWeight.w800,
                                  color: link,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: chromeGap),
              const ShellThemeToggle(size: DashboardLayout.touchTarget),
              SizedBox(width: chromeGap),
              const NotificacaoBadgeButton(size: DashboardLayout.touchTarget),
              SizedBox(width: chromeGap),
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
