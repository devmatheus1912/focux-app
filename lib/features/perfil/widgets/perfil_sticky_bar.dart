import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../constants/perfil_layout.dart';

/// Chip flutuante — paridade [`DashboardPrioritiesOverlay`]: só Hoje/Completar.
class PerfilStickyBar extends StatelessWidget {
  const PerfilStickyBar({
    super.key,
    required this.accent,
    required this.isDark,
    required this.profileComplete,
    required this.visible,
  });

  final Color accent;
  final bool isDark;
  final bool profileComplete;
  final bool visible;

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
    final primaryLabel = profileComplete ? 'Hoje' : 'Completar';
    final chipFg = dashboardPrioritiesChipForeground(accent, isDark: isDark);
    final chipBg = dashboardPrioritiesChipBackground(accent, isDark: isDark);

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.35),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              TokensStrip.s4,
              0,
              TokensStrip.s4,
              PerfilLayout.stickyBottomInset,
            ),
            child: Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: Semantics(
                button: true,
                label: profileComplete ? 'Abrir Hoje' : 'Completar perfil',
                child: Material(
                  color: chipBg,
                  elevation: isDark ? 4 : 2,
                  shadowColor: accent.withValues(alpha: isDark ? 0.38 : 0.14),
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
            ),
          ),
        ),
      ),
    );
  }
}
