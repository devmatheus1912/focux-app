import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../platform/focux_platform.dart';

/// Centers shell content on wide screens (tablet / desktop).
///
/// When the parent gives a **bounded height** (Scaffold body, [SizedBox.expand]),
/// this widget fills that height so scrollables get a real viewport. A plain
/// [Align] alone loosens height to `0…max` and can collapse paywall/ListView
/// bodies — sticky footers then jump to the top.
///
/// No [Scaffold.bottomNavigationBar] o maxHeight é a tela: use
/// [expandHeight] `false` só para capar largura.
class FxContentWidthLimiter extends StatelessWidget {
  const FxContentWidthLimiter({
    super.key,
    required this.child,
    this.maxWidth = FocuxPlatform.desktopMaxContent,
    this.expandHeight = true,
  });

  final Widget child;
  final double maxWidth;

  /// Preenche a altura bounded (body + ListView). No [bottomNavigationBar]
  /// do Scaffold o maxHeight é a tela inteira — deixar true some o body.
  final bool expandHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite
                ? math.min(constraints.maxWidth, maxWidth)
                : maxWidth;
        final fillHeight =
            expandHeight &&
            constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight > 0;

        // Row (não Align): Align com constraint bounded estica na vertical e
        // no bottomNavigationBar some o body do paywall.
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: width,
              height: fillHeight ? constraints.maxHeight : null,
              child: child,
            ),
          ],
        );
      },
    );
  }
}
