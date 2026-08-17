import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../constants/perfil_layout.dart';

/// Sticky quiet do Perfil — paridade Home [`DashboardPrioritiesOverlay`]:
/// 1 chip primário + atalho texto; sem barra full-bleed de botões liquid.
class PerfilStickyBar extends StatelessWidget {
  const PerfilStickyBar({
    super.key,
    required this.accent,
    required this.actionInk,
    required this.isDark,
    required this.profileComplete,
  });

  final Color accent;
  final Color actionInk;
  final bool isDark;
  final bool profileComplete;

  void _track(String cta) {
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.perfilStickyTapped,
        props: {'cta': cta, 'profileComplete': profileComplete},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final primaryLabel = profileComplete ? 'Hoje' : 'Completar';
    final chipFg = dashboardPrioritiesChipForeground(accent, isDark: isDark);
    final chipBg = dashboardPrioritiesChipBackground(accent, isDark: isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        PerfilLayout.stickyBottomInset,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: 'Meus alunos',
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _track('alunos');
                    goPersonalShellTab(context, '/alunos');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: chrome.mute,
                    minimumSize: const Size(
                      48,
                      PerfilLayout.stickyRowHeight,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Meus alunos',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.bodyMuted(
                      color: chrome.mute,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: profileComplete ? 'Abrir Hoje' : 'Completar perfil',
            child: Material(
              color: chipBg,
              elevation: isDark ? 4 : 2,
              shadowColor: accent.withValues(alpha: isDark ? 0.4 : 0.16),
              shape: const StadiumBorder(),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (profileComplete) {
                    _track('hoje');
                    goPersonalShellTab(context, '/dashboard/personal');
                    return;
                  }
                  _track('completar');
                  context.push('/identidade-visual');
                },
                customBorder: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  child: Text(
                    primaryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: dashboardChipLabelStyle(chipFg).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
