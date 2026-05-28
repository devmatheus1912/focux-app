import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'cinematic_mesh_background.dart';
import 'fx_glass_surface.dart';
import 'fx_icon.dart';
import 'mesh_scope.dart';
import 'fx_premium_entrance.dart';

/// Premium scaffold for shell tabs and standalone screens.
class FxShellScaffold extends StatelessWidget {
  const FxShellScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.useMesh = false,
    this.safeArea = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool useMesh;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meshActive = MeshScope.of(context);
    final needsMesh = useMesh && !meshActive;

    Widget content = FxPremiumEntrance(child: body);
    if (safeArea) {
      content = SafeArea(
        bottom: bottomNavigationBar == null,
        child: FxPremiumEntrance(child: body),
      );
    }

    final scaffold = Scaffold(
      extendBody: extendBody,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: content,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );

    if (!needsMesh) return scaffold;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: CinematicMeshBackground(
        showCenterGlow: false,
        showCornerGlow: true,
        child: MeshScope(active: true, child: scaffold),
      ),
    );
  }
}

/// Consistent back-navigation app bar over mesh.
class FxShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FxShellAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.onBack,
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onBack;
  final bool centerTitle;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 56 : 64);

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      leading:
          leading ??
          IconButton(
            onPressed: onBack ?? () => Navigator.maybePop(context),
            icon: Container(
              width: 38,
              height: 38,
              decoration: chrome.headerAction(radius: 12),
              child: Center(
                child: FxIcon(name: 'arrow-left', size: 18, color: ink),
              ),
            ),
          ),
      title:
          subtitle == null
              ? Text(
                title,
                style: TokensStrip.h2(
                  color: ink,
                  fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TokensStrip.h2(
                      color: ink,
                      fontFamily:
                          Theme.of(context).textTheme.bodyLarge?.fontFamily,
                    ).copyWith(fontSize: 17),
                  ),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TokensStrip.bodyMuted(
                      color: mute,
                      fontFamily:
                          Theme.of(context).textTheme.bodyLarge?.fontFamily,
                    ).copyWith(fontSize: 11.5, height: 1.1),
                  ),
                ],
              ),
      actions: [
        ...?actions,
        const ShellThemeToggle(size: 38),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Drop-in Liquid Glass card surface for lists and panels.
class ShellSurface extends StatelessWidget {
  const ShellSurface({
    super.key,
    required this.child,
    this.accent,
    this.radius = TokensStrip.rCard,
    this.padding,
    this.onTap,
    this.blur = false,
    this.glow = false,
  });

  final Widget child;
  final Color? accent;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool blur;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return FxGlassSurface(
      radius: radius,
      padding: padding,
      accent: accent,
      blur: blur,
      glow: glow,
      onTap: onTap,
      child: child,
    );
  }
}

/// Resolves list/card fill to ShellChrome glass in both themes.
BoxDecoration fxListCardDecoration(
  BuildContext context, {
  Color? accent,
  double radius = TokensStrip.rCard,
  bool selected = false,
}) {
  final chrome = ShellChrome.of(context);
  if (selected && accent != null) {
    return chrome.listCard(selected: true, primary: accent, radius: radius);
  }
  return chrome.panel(radius: radius, accent: accent);
}

Color fxScreenInk(BuildContext context) => ShellChrome.of(context).ink;

Color fxScreenMute(BuildContext context) => ShellChrome.of(context).mute;

/// TOKENS STRIP card — white surface + visible teal depth glow (showcase spec).
BoxDecoration fxStripCardDecoration(
  BuildContext context, {
  Color? accent,
  double radius = TokensStrip.rCard,
  double glowStrength = 0.44,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primary = accent ?? Theme.of(context).colorScheme.primary;

  if (isDark) {
    return ShellChrome.of(context).panel(
      radius: radius,
      accent: primary,
      elevationLevel: 8,
    );
  }

  return BoxDecoration(
    color: TokensStrip.cardBg,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: primary.withValues(alpha: 0.16), width: 1),
    boxShadow: [
      ...TokensStrip.cardShadow(),
      ...TokensStrip.coloredDepthGlow(primary, strength: glowStrength),
    ],
  );
}
