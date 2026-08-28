import 'package:flutter/material.dart';

import '../theme/fx_settings_layout.dart';
import 'fx_help.dart';
import 'fx_shell_scaffold.dart';

/// Grupo inset (ChatGPT/iOS) — superfície da Home, tamanhos de [FxSettingsLayout].
class FxSettingsGroup extends StatelessWidget {
  const FxSettingsGroup({
    super.key,
    this.header,
    this.caption,
    required this.children,
    this.footer,
    this.accent,
    this.helpTooltip,
    this.onHelpTap,
  });

  final String? header;
  final String? caption;
  final List<Widget> children;
  final Widget? footer;
  final Color? accent;
  final String? helpTooltip;
  final VoidCallback? onHelpTap;

  @override
  Widget build(BuildContext context) {
    final mute = fxScreenMute(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FxSettingsLayout.groupPadH,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    header!,
                    style: FxSettingsLayout.sectionHeader(color: mute),
                  ),
                ),
                if (onHelpTap != null)
                  FxHelpIconButton(
                    tooltip: helpTooltip ?? 'Ajuda sobre $header',
                    onTap: onHelpTap!,
                    size: 28,
                  ),
              ],
            ),
          ),
        if (caption != null) ...[
          if (header != null)
            const SizedBox(height: FxSettingsLayout.captionAfterHeader),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FxSettingsLayout.groupPadH,
            ),
            child: Text(
              caption!,
              style: FxSettingsLayout.footer(color: mute),
            ),
          ),
        ],
        if (header != null || caption != null)
          const SizedBox(height: FxSettingsLayout.headerToGroup),
        DecoratedBox(
          decoration: fxListCardDecoration(
            context,
            accent: accent,
            radius: FxSettingsLayout.groupRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FxSettingsLayout.groupPadH,
              vertical: FxSettingsLayout.groupPadV,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: FxSettingsLayout.footerAfterGroup),
          footer!,
        ],
      ],
    );
  }
}
