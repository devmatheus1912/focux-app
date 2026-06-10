import 'package:flutter/material.dart';

import '../../../core/utils/motion_preferences.dart';

/// Staggered entrance for progressão exercise cards.
class IaProgressaoCardEntrance extends StatefulWidget {
  const IaProgressaoCardEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<IaProgressaoCardEntrance> createState() =>
      _IaProgressaoCardEntranceState();
}

class _IaProgressaoCardEntranceState extends State<IaProgressaoCardEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  var _played = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = curve;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_played) return;
    _played = true;
    if (reduceMotionOf(context)) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(Duration(milliseconds: 40 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
