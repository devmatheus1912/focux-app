import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../platform/focux_platform.dart';

/// Centers shell content on wide screens (tablet / desktop).
///
/// When the parent gives a **bounded height** (Scaffold body, [SizedBox.expand]),
/// this widget fills that height so scrollables get a real viewport. A plain
/// [Align] alone loosens height to `0…max` and can collapse paywall/ListView
/// bodies — sticky footers then jump to the top.
class FxContentWidthLimiter extends StatelessWidget {
  const FxContentWidthLimiter({
    super.key,
    required this.child,
    this.maxWidth = FocuxPlatform.desktopMaxContent,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite
                ? math.min(constraints.maxWidth, maxWidth)
                : maxWidth;
        final fillHeight =
            constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight > 0;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: fillHeight ? constraints.maxHeight : null,
            child: child,
          ),
        );
      },
    );
  }
}
