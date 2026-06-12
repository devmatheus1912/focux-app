import 'package:flutter/material.dart';

import '../platform/focux_platform.dart';

/// Centers shell content on wide screens (tablet / desktop).
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
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
