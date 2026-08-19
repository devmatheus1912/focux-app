import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/hero_teal.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'fx_icon.dart';
import 'fx_shell_scaffold.dart';

/// Chrome canônico do ícone de ajuda — paridade Home (`DashboardHomeHeader` 36pt).
abstract final class FxHelpChrome {
  FxHelpChrome._();

  static const double iconSize = 36;
  static const double gap = 3;
  static const double touchTarget = 48;
  static const String iconName = 'help';
}

class FxHelpTip {
  const FxHelpTip(this.title, this.body);

  final String title;
  final String body;
}

/// `?` circular da Home. Use em todo header e ajuda inline.
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
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: fxTransparent,
    barrierColor: heroScrim(0.34),
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
    final primary = Theme.of(context).colorScheme.primary;
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.72;
    final bottom = math.max(
      12.0,
      math.max(media.viewPadding.bottom + 10, media.viewInsets.bottom + 12),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: fxStripCardDecoration(
          context,
          radius: 28,
          glowStrength: isDark ? 0.10 : 0.16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: chrome.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: TokensStrip.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: BrandPalette.soft(primary, dark: isDark),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: FxIcon(
                      name: FxHelpChrome.iconName,
                      color: primary,
                      size: 18,
                    ),
                  ),
                ),
                SizedBox(width: TokensStrip.s3),
                Expanded(
                  child: Semantics(
                    header: true,
                    label: '$title. $subtitle',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TokensStrip.h2(
                            color: primary,
                            fontFamily:
                                Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        SizedBox(height: TokensStrip.s1),
                        Text(
                          subtitle,
                          style: FocuxHubTypography.bodyMuted(
                            color: chrome.mute,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(
                      FxHelpChrome.touchTarget,
                      FxHelpChrome.touchTarget,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: chrome.mute,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 22),
                ),
              ],
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
      ),
    );
  }
}
