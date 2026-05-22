import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/shell_chrome.dart';
import 'cinematic_mesh_background.dart';
import 'fx_icon.dart';
import 'mesh_scope.dart';

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

    Widget content = body;
    if (safeArea) {
      content = SafeArea(bottom: bottomNavigationBar == null, child: body);
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
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ink,
                  letterSpacing: -0.4,
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ink,
                      letterSpacing: -0.35,
                    ),
                  ),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 11.5, color: mute, height: 1.1),
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

/// Drop-in glass card surface for lists and panels.
class ShellSurface extends StatelessWidget {
  const ShellSurface({
    super.key,
    required this.child,
    this.accent,
    this.radius = 20,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final Color? accent;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final decoration = chrome.panel(radius: radius, accent: accent);

    Widget card = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Resolves list/card fill to ShellChrome glass in both themes.
BoxDecoration fxListCardDecoration(
  BuildContext context, {
  Color? accent,
  double radius = 20,
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
