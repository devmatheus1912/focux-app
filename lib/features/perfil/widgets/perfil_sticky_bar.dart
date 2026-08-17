import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';

/// Sticky do hub Perfil — paridade Home: 1 CTA primário, IA só no dock.
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
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: chrome.sheetFill.withValues(alpha: isDark ? 0.96 : 0.98),
          border: Border(
            top: BorderSide(color: chrome.line.withValues(alpha: 0.55)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s4,
              10,
              TokensStrip.s4,
              12,
            ),
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Meus alunos',
                      child: FxLiquidSecondaryButton(
                        expand: true,
                        icon: Icons.groups_2_outlined,
                        label: 'Meus alunos',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _track('alunos');
                          goPersonalShellTab(context, '/alunos');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: TokensStrip.s3),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label:
                          profileComplete ? 'Abrir Hoje' : 'Completar perfil',
                      child: FxLiquidPrimaryButton(
                        expand: true,
                        icon:
                            profileComplete
                                ? Icons.today_outlined
                                : Icons.checklist_rtl_rounded,
                        label: profileComplete ? 'Hoje' : 'Completar perfil',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          if (profileComplete) {
                            _track('hoje');
                            goPersonalShellTab(
                              context,
                              '/dashboard/personal',
                            );
                            return;
                          }
                          _track('completar');
                          context.push('/identidade-visual');
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
