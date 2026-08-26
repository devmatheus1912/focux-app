import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand_palette.dart';
import '../theme/fx_settings_layout.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'fx_home_sheet.dart';
import 'fx_icon.dart';

/// Chrome canônico do ícone de ajuda — paridade Home (`DashboardHomeHeader` 36pt).
abstract final class FxHelpChrome {
  FxHelpChrome._();

  static const double iconSize = 36;
  static const double glyphSize = FxSettingsLayout.iconSize;
  static const double gap = 3;
  static const double touchTarget = 48;
  static const String iconName = 'help';
}

class FxHelpTip {
  const FxHelpTip(this.title, this.body, {this.icon});

  final String title;
  final String body;
  final String? icon;
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
  String? footer,
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
        footer: footer,
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
    this.footer,
    this.extra = const [],
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final List<FxHelpTip> tips;
  final String? footer;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final brand = BrandPalette.softened(Theme.of(context).colorScheme.primary);
    final maxHeight =
        MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor;
    final footnote = footer?.trim();
    final hasFootnote = footnote != null && footnote.isNotEmpty;

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (tips.isNotEmpty)
                    for (var i = 0; i < tips.length; i++)
                      FxHelpTipRow(
                        tip: tips[i],
                        showDivider: i < tips.length - 1,
                      ),
                  if (hasFootnote) ...[
                    if (tips.isNotEmpty)
                      SizedBox(height: FxSettingsLayout.footerAfterGroup),
                    Text(
                      footnote,
                      style: FxSettingsLayout.footer(color: chrome.mute),
                    ),
                  ],
                  if ((tips.isNotEmpty || hasFootnote) && extra.isNotEmpty)
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

/// Linha de ajuda inset — título + caption, sem chevron (não navega).
class FxHelpTipRow extends StatelessWidget {
  const FxHelpTipRow({super.key, required this.tip, required this.showDivider});

  final FxHelpTip tip;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final brand = BrandPalette.softened(Theme.of(context).colorScheme.primary);
    final iconName = tip.icon;

    return Semantics(
      container: true,
      label: '${tip.title}. ${tip.body}',
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: FxSettingsLayout.rowMinHeight,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (iconName != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: FxIcon(
                  name: iconName,
                  size: FxSettingsLayout.iconSize,
                  color: brand,
                ),
              ),
              const SizedBox(width: FxSettingsLayout.iconGap),
            ],
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border:
                      showDivider
                          ? Border(
                            bottom: BorderSide(
                              color: chrome.line,
                              width: FxSettingsLayout.dividerThickness,
                            ),
                          )
                          : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.title,
                        style: FxSettingsLayout.rowLabel(color: chrome.ink),
                      ),
                      const SizedBox(
                        height: FxSettingsLayout.captionAfterHeader,
                      ),
                      Text(
                        tip.body,
                        style: FxSettingsLayout.subhead(color: chrome.mute),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
