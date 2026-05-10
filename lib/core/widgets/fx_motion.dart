import 'package:flutter/material.dart';

/// Tactile spring button — scales down on press, bounces back on release.
/// Use this wrapper around any CTA, card, or interactive element for
/// premium tactile feedback without managing AnimationControllers manually.
///
/// ```dart
/// FxSpringButton(
///   onTap: () => doSomething(),
///   child: Container(/* your button visuals */),
/// )
/// ```
class FxSpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;

  const FxSpringButton({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.96,
  });

  @override
  State<FxSpringButton> createState() => _FxSpringButtonState();
}

class _FxSpringButtonState extends State<FxSpringButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _ctrl.reverse();
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => _ctrl.reverse() : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Staggered fade-slide animation for list items.
/// Wraps any child in a slide-up + fade-in animation with configurable delay.
///
/// ```dart
/// ListView.builder(
///   itemBuilder: (ctx, i) => FxStaggerItem(
///     index: i,
///     child: YourListTile(...),
///   ),
/// )
/// ```
class FxStaggerItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration staggerDelay;
  final Duration duration;
  final double slideOffset;

  const FxStaggerItem({
    super.key,
    required this.index,
    required this.child,
    this.staggerDelay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 400),
    this.slideOffset = 20,
  });

  @override
  State<FxStaggerItem> createState() => _FxStaggerItemState();
}

class _FxStaggerItemState extends State<FxStaggerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final delay = widget.staggerDelay * widget.index;
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: _slide.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
