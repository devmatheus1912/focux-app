import 'package:flutter/material.dart';

/// Fade nas bordas para indicar scroll horizontal (compartilhado).
/// O fade inicial só aparece depois que o conteúdo já saiu da origem —
/// evita um “8” órfão no lugar do chip Todos.
class FxHorizontalScrollPeek extends StatefulWidget {
  const FxHorizontalScrollPeek({
    super.key,
    required this.child,
    required this.showPeek,
    this.showStartPeek = false,
  });

  final Widget child;
  final bool showPeek;
  final bool showStartPeek;

  @override
  State<FxHorizontalScrollPeek> createState() => _FxHorizontalScrollPeekState();
}

class _FxHorizontalScrollPeekState extends State<FxHorizontalScrollPeek> {
  bool _scrolledFromStart = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.showPeek && !widget.showStartPeek) return widget.child;

    final base = Theme.of(context).scaffoldBackgroundColor;
    final showStart = widget.showStartPeek && _scrolledFromStart;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis != Axis.horizontal) return false;
        final scrolled = notification.metrics.pixels > 6;
        if (scrolled != _scrolledFromStart) {
          setState(() => _scrolledFromStart = scrolled);
        }
        return false;
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Semantics(
            label: 'Deslize horizontalmente para ver mais',
            child: widget.child,
          ),
          if (showStart)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        base.withValues(alpha: 0),
                        base.withValues(alpha: 0.94),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (widget.showPeek)
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
      ),
    );
  }
}
