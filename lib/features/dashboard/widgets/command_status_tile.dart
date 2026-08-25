import 'package:flutter/material.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../utils/dashboard_readability.dart';

/// Empty / unavailable — linha inset, ícone outline sem poço.
class CommandStatusTile extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final IconData icon;
  final String title;
  final String subtitle;

  const CommandStatusTile({
    super.key,
    required this.isDark,
    required this.primary,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final mute = dashboardReadableCaption(context, isDark: isDark);
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: FxSettingsLayout.rowMinHeight,
      ),
      child: Row(
        children: [
          Icon(icon, size: FxSettingsLayout.iconSize, color: primary),
          const SizedBox(width: FxSettingsLayout.iconGap),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.cardTitle(color: chrome.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.bodyMuted(color: mute),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
