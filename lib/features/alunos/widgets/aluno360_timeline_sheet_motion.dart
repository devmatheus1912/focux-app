import 'package:flutter/material.dart';

import '../../../core/utils/motion_preferences.dart';

/// Subtle entrance for timeline bottom sheets (respects reduce motion).
class Aluno360TimelineSheetEntrance extends StatefulWidget {
  const Aluno360TimelineSheetEntrance({super.key, required this.child});

  final Widget child;

  @override
  State<Aluno360TimelineSheetEntrance> createState() =>
      _Aluno360TimelineSheetEntranceState();
}

class _Aluno360TimelineSheetEntranceState
    extends State<Aluno360TimelineSheetEntrance>
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
      duration: const Duration(milliseconds: 260),
    );
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
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
    _controller.forward();
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
