import 'package:flutter/material.dart';

import '../theme/tokens_strip.dart';
import 'fx_shell_scaffold.dart';

/// Standard TOKENS STRIP sub-screen wrapper — mesh + shell app bar + body padding.
class FxStripSubScreen extends StatelessWidget {
  const FxStripSubScreen({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.onBack,
    this.actions,
    this.bottomBar,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 32),
    this.useMesh = true,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Widget? bottomBar;
  final EdgeInsetsGeometry padding;
  final bool useMesh;

  @override
  Widget build(BuildContext context) {
    return FxShellScaffold(
      useMesh: useMesh,
      appBar: FxShellAppBar(
        title: title,
        subtitle: subtitle,
        onBack: onBack,
        actions: actions,
      ),
      bottomNavigationBar: bottomBar,
      body: SingleChildScrollView(
        padding: padding,
        child: body,
      ),
    );
  }
}

/// Standard list sub-screen (non-scroll body — caller provides scroll).
class FxStripSubScreenBody extends StatelessWidget {
  const FxStripSubScreenBody({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.onBack,
    this.actions,
    this.bottomBar,
    this.useMesh = true,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Widget? bottomBar;
  final bool useMesh;

  @override
  Widget build(BuildContext context) {
    return FxShellScaffold(
      useMesh: useMesh,
      appBar: FxShellAppBar(
        title: title,
        subtitle: subtitle,
        onBack: onBack,
        actions: actions,
      ),
      bottomNavigationBar: bottomBar,
      body: body,
    );
  }
}

/// Screen content padding per TOKENS STRIP grid.
class FxStripLayout {
  static const screenPadding = EdgeInsets.fromLTRB(20, 8, 20, 32);
  static const cardPadding = EdgeInsets.all(TokensStrip.s4);
  static const sectionGap = SizedBox(height: TokensStrip.s5);
}
