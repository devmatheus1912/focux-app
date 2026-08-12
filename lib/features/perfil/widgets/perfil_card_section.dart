import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';

/// Card de seção do hub Perfil (título + subtítulo + trailing opcional).
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
  });

  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final bool isDark;
  final Color accent;
  final Color actionInk;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final a11yTitle = subtitle == null ? title : '$title. $subtitle';

    return Semantics(
      container: true,
      label: a11yTitle,
      child: Container(
        decoration: chrome.panel(radius: 16, accent: accent),
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s4),
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
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: TokensStrip.s1),
                          Text(
                            subtitle!,
                            style: TokensStrip.bodyMuted(color: mute).copyWith(
                              height: 1.35,
                            ),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(
                                alpha: isDark ? 0.16 : 0.10,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  trailingLabel!,
                                  style: TokensStrip.bodyMuted(
                                    color: actionInk,
                                  ).copyWith(
                                    fontSize: TokensStrip.fontBodySm - 2,
                                    fontWeight: FontWeight.w800,
                                  ),
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
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
