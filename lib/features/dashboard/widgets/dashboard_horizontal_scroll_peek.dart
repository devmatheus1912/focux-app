import 'package:flutter/material.dart';

/// Fade na borda direita para indicar scroll horizontal.
class DashboardHorizontalScrollPeek extends StatelessWidget {
  const DashboardHorizontalScrollPeek({
    super.key,
    required this.child,
    required this.showPeek,
  });

  final Widget child;
  final bool showPeek;

  @override
  Widget build(BuildContext context) {
    if (!showPeek) return child;

    final base = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Semantics(
          label: 'Deslize horizontalmente para ver mais',
          child: child,
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    base.withValues(alpha: 0),
                    base.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
