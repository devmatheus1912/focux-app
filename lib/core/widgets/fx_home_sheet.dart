import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/hero_teal.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'fx_shell_scaffold.dart';

/// Chrome canônico de sheet — paridade Command Priorities / ajuda da Home.
abstract final class FxHomeSheetChrome {
  FxHomeSheetChrome._();

  static const double radius = 28;
  static const double sidePad = 14;
  static const double handleWidth = 42;
  static const double handleHeight = 4;
  static const double leadingSize = 38;
  static const double maxHeightFactor = 0.72;
  static const double expandHeightFactor = 0.92;
  static const double touchTarget = 48;
  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(18, 10, 18, 18);

  static double glow(bool isDark) => isDark ? 0.10 : 0.16;

  static Color barrier([bool isDark = false]) =>
      heroScrim(isDark ? 0.34 : 0.28);

  static EdgeInsets paddingOf(BuildContext context) {
    final media = MediaQuery.of(context);
    return EdgeInsets.fromLTRB(
      sidePad,
      0,
      sidePad,
      math.max(
        12,
        math.max(media.viewPadding.bottom + 10, media.viewInsets.bottom + 12),
      ),
    );
  }
}

/// Abre sheet no contrato da Home: card flutuante, scrim, root navigator.
Future<T?> showFxHomeSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool useRootNavigator = true,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: fxTransparent,
    barrierColor: FxHomeSheetChrome.barrier(isDark),
    builder: (ctx) {
      final maxH =
          MediaQuery.sizeOf(ctx).height * FxHomeSheetChrome.expandHeightFactor;
      return _FxHomeSheetEnter(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: builder(ctx),
          ),
        ),
      );
    },
  );
}

class _FxHomeSheetEnter extends StatefulWidget {
  const _FxHomeSheetEnter({required this.child});

  final Widget child;

  @override
  State<_FxHomeSheetEnter> createState() => _FxHomeSheetEnterState();
}

class _FxHomeSheetEnterState extends State<_FxHomeSheetEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (TokensStrip.prefersReducedMotion(context)) return widget.child;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class FxHomeSheetHandle extends StatelessWidget {
  const FxHomeSheetHandle({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final line = ShellChrome.forDark(isDark).line;
    return Center(
      child: Container(
        width: FxHomeSheetChrome.handleWidth,
        height: FxHomeSheetChrome.handleHeight,
        decoration: BoxDecoration(
          color: line,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class FxHomeSheetSurface extends StatelessWidget {
  const FxHomeSheetSurface({
    super.key,
    required this.isDark,
    required this.child,
    this.maxHeight,
    this.expand = false,
    this.padding = FxHomeSheetChrome.contentPadding,
  });

  final bool isDark;
  final Widget child;
  final double? maxHeight;
  final bool expand;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: FxHomeSheetChrome.paddingOf(context),
      child: Container(
        constraints:
            maxHeight == null
                ? null
                : expand
                ? BoxConstraints.tightFor(height: maxHeight)
                : BoxConstraints(maxHeight: maxHeight!),
        clipBehavior: Clip.antiAlias,
        padding: padding,
        decoration: fxStripCardDecoration(
          context,
          radius: FxHomeSheetChrome.radius,
          glowStrength: FxHomeSheetChrome.glow(isDark),
        ),
        child: child,
      ),
    );
  }
}

class FxHomeSheetHeader extends StatelessWidget {
  const FxHomeSheetHeader({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.isDark,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool? isDark;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final caption = ShellChrome.forDark(dark).mute;
    final subtitleText = subtitle?.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            width: FxHomeSheetChrome.leadingSize,
            height: FxHomeSheetChrome.leadingSize,
            decoration: BoxDecoration(
              color: BrandPalette.soft(primary, dark: dark),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(child: leading),
          ),
        ),
        SizedBox(width: TokensStrip.s3),
        Expanded(
          child: Semantics(
            header: true,
            label:
                subtitleText == null || subtitleText.isEmpty
                    ? title
                    : '$title. $subtitleText',
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
                        Theme.of(context).textTheme.bodyLarge?.fontFamily,
                  ),
                ),
                if (subtitleText != null && subtitleText.isNotEmpty) ...[
                  SizedBox(height: TokensStrip.s1),
                  Text(
                    subtitleText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.bodyMuted(
                      color: caption,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        trailing ??
            IconButton(
              tooltip: 'Fechar',
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                minimumSize: const Size(
                  FxHomeSheetChrome.touchTarget,
                  FxHomeSheetChrome.touchTarget,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: caption,
              ),
              icon: const Icon(Icons.close_rounded, size: 22),
            ),
      ],
    );
  }
}

/// Handle + header + corpo no card da Home. Use para migrar sheets de uma vez.
class FxHomeSheetScaffold extends StatelessWidget {
  const FxHomeSheetScaffold({
    super.key,
    required this.isDark,
    required this.leading,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.maxHeightFactor = FxHomeSheetChrome.maxHeightFactor,
    this.scroll = true,
    this.padding = FxHomeSheetChrome.contentPadding,
  });

  final bool isDark;
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final double maxHeightFactor;
  final bool scroll;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;
    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight: maxHeight,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            leading: leading,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
          ),
          SizedBox(height: TokensStrip.s3),
          if (scroll)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight - 120),
              child: SingleChildScrollView(child: child),
            )
          else
            child,
        ],
      ),
    );
  }
}
