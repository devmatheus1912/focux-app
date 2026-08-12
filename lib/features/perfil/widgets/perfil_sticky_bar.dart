import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';

/// Sticky do hub Perfil — peso visual equilibrado quando o perfil está completo.
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

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: chrome.sheetFill.withValues(alpha: isDark ? 0.96 : 0.98),
          border: Border(
            top: BorderSide(color: chrome.line.withValues(alpha: 0.7)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
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
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: actionInk,
                          side: BorderSide(color: accent.withValues(alpha: 0.45)),
                          minimumSize: const Size(0, 48),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          goPersonalShellTab(context, '/alunos');
                        },
                        icon: const Icon(Icons.groups_2_outlined, size: 18),
                        label: const Text('Meus alunos'),
                      ),
                    ),
                  ),
                  const SizedBox(width: TokensStrip.s3),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label:
                          profileComplete
                              ? 'Copiloto IA'
                              : 'Completar perfil',
                      child:
                          profileComplete
                              ? OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: actionInk,
                                  side: BorderSide(
                                    color: accent.withValues(alpha: 0.55),
                                  ),
                                  minimumSize: const Size(0, 48),
                                ),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  goPersonalShellTab(context, '/ia/copiloto');
                                },
                                icon: const Icon(
                                  Icons.auto_awesome_outlined,
                                  size: 18,
                                ),
                                label: const Text('Copiloto IA'),
                              )
                              : FxLiquidPrimaryButton(
                                expand: true,
                                icon: Icons.checklist_rtl_rounded,
                                label: 'Completar perfil',
                                onPressed: () {
                                  HapticFeedback.selectionClick();
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
