import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/tokens_strip.dart';
import 'fx_shell_scaffold.dart';

/// Soft hub header strip — title + optional freshness, Home chrome weight.
class FxHubHeader extends StatelessWidget {
  const FxHubHeader({
    super.key,
    required this.title,
    this.freshnessLabel,
    this.subtitle,
    this.trailing,
    this.quietChrome = false,
    this.onTitleTap,
  });

  final String title;
  final String? freshnessLabel;
  final String? subtitle;
  final Widget? trailing;
  final bool quietChrome;
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final glow = quietChrome ? 0.02 : 0.04;
    final titleText = Text(
      title,
      style: FocuxHubTypography.sectionTitle(context, color: ink),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Semantics(
      header: true,
      button: onTitleTap != null,
      label: [
        title,
        if (freshnessLabel != null && freshnessLabel!.isNotEmpty) freshnessLabel!,
      ].join('. '),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          TokensStrip.s4,
          quietChrome ? TokensStrip.s3 : TokensStrip.s4,
          TokensStrip.s4,
          TokensStrip.s3,
        ),
        decoration: fxStripCardDecoration(
          context,
          glowStrength: glow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onTitleTap != null)
                    GestureDetector(
                      onTap: onTitleTap,
                      behavior: HitTestBehavior.opaque,
                      child: titleText,
                    )
                  else
                    titleText,
                  if (freshnessLabel != null && freshnessLabel!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      freshnessLabel!,
                      style: FocuxHubTypography.bodyMuted(color: mute),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: FocuxHubTypography.bodyMuted(color: mute),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
