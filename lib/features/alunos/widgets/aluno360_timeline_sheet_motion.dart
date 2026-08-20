import 'package:flutter/material.dart';

import '../../../core/utils/motion_preferences.dart';

/// Staggered entrance for timeline preview tiles (respects reduce motion).
class Aluno360TimelineTileEntrance extends StatefulWidget {
  const Aluno360TimelineTileEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<Aluno360TimelineTileEntrance> createState() =>
      _Aluno360TimelineTileEntranceState();
}

class _Aluno360TimelineTileEntranceState
    extends State<Aluno360TimelineTileEntrance>
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
      begin: const Offset(0, 0.03),
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
    final delay = Duration(milliseconds: 36 * widget.index.clamp(0, 8));
    Future<void>.delayed(delay, () {
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
