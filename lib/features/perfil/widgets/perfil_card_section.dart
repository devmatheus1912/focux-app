import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Card de seção do hub Perfil — mesma superfície strip da Home.
class PerfilCardSection extends StatelessWidget {
  const PerfilCardSection({
    super.key,
    required this.title,
    required this.isDark,
    required this.child,
    this.subtitle,
    this.trailingLabel,
    this.onTrailingTap,
    required this.accent,
    required this.actionInk,
    this.quiet = false,
  });

  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final bool isDark;
  final Color accent;
  final Color actionInk;
  final Widget child;
  /// Secundário: menos glow (paridade Home quietChrome).
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final a11yTitle = subtitle == null ? title : '$title. $subtitle';
    final pad = quiet ? 12.0 : 14.0;

    return Semantics(
      container: true,
      label: a11yTitle,
      child: Container(
        decoration: fxStripCardDecoration(
          context,
          accent: quiet ? null : accent,
          radius: TokensStrip.rCard,
          glowStrength: quiet ? 0.03 : 0.06,
        ),
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: FocuxHubTypography.sectionTitle(
                            context,
                            color: ink,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: FocuxHubTypography.bodyMuted(color: mute),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailingLabel != null && onTrailingTap != null)
                    Semantics(
                      button: true,
                      label: '$trailingLabel $title',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTrailingTap!();
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  trailingLabel!,
                                  style: FocuxHubTypography.chip(actionInk),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.north_east,
                                  size: 13,
                                  color: actionInk,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: quiet ? 10 : 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
