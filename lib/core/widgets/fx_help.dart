import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand_palette.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/fx_settings_layout.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'fx_home_sheet.dart';
import 'fx_icon.dart';

/// Chrome canônico do ícone de ajuda — paridade Home (`DashboardHomeHeader` 36pt).
/// Glifo = `?` outline (Perfil). O círculo é só o well do header.
abstract final class FxHelpChrome {
  FxHelpChrome._();

  static const double iconSize = 36;
  static const double glyphSize = FxSettingsLayout.iconSize;
  static const double gap = 3;
  static const double touchTarget = 48;
  static const String iconName = 'help';
}

class FxHelpTip {
  const FxHelpTip(this.title, this.body);

  final String title;
  final String body;
}

/// `?` no well circular da Home. Use em todo header e ajuda inline.
class FxHelpIconButton extends StatelessWidget {
  const FxHelpIconButton({
    super.key,
    required this.tooltip,
    required this.onTap,
    this.size = FxHelpChrome.iconSize,
    this.expandHitTarget = false,
  });

  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final bool expandHitTarget;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      label: tooltip,
      child: ShellHeaderIconButton(
        icon: FxHelpChrome.iconName,
        size: size,
        tooltip: tooltip,
        onTap: onTap,
      ),
    );

    if (!expandHitTarget) return button;
    return SizedBox(
      width: FxHelpChrome.touchTarget,
      height: FxHelpChrome.touchTarget,
      child: Center(child: button),
    );
  }
}

Future<void> showFxHelpSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  List<FxHelpTip> tips = const [],
  List<Widget> extra = const [],
}) {
  HapticFeedback.selectionClick();
  return showFxHomeSheet<void>(
    context,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return FxHelpSheetFrame(
        isDark: isDark,
        title: title,
        subtitle: subtitle,
        tips: tips,
        extra: extra,
      );
    },
  );
}

class FxHelpSheetFrame extends StatelessWidget {
  const FxHelpSheetFrame({
    super.key,
    required this.isDark,
    required this.title,
    required this.subtitle,
    this.tips = const [],
    this.extra = const [],
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final List<FxHelpTip> tips;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final brand = BrandPalette.softened(Theme.of(context).colorScheme.primary);
    final maxHeight =
        MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor;

    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight: maxHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: title,
            subtitle: subtitle,
            leading: FxIcon(
              name: FxHelpChrome.iconName,
              color: brand,
              size: FxHelpChrome.glyphSize,
            ),
          ),
          SizedBox(height: TokensStrip.s4),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < tips.length; i++) ...[
                    Text(
                      tips[i].title,
                      style: FocuxHubTypography.sectionTitle(
                        context,
                        color: chrome.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tips[i].body,
                      style: FocuxHubTypography.bodyMuted(
                        color: chrome.mute,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (i < tips.length - 1) SizedBox(height: TokensStrip.s3),
                  ],
                  if (tips.isNotEmpty && extra.isNotEmpty)
                    SizedBox(height: TokensStrip.s3),
                  ...extra,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
