import 'package:flutter/material.dart';

/// Abre bottom sheet com entrada suave (slide + fade).
Future<T?> showFxBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  double barrierOpacity = 0.52,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: barrierOpacity),
    builder: (sheetContext) => _FxSheetEnter(child: builder(sheetContext)),
  );
}

class _FxSheetEnter extends StatefulWidget {
  const _FxSheetEnter({required this.child});

  final Widget child;

  @override
  State<_FxSheetEnter> createState() => _FxSheetEnterState();
}

class _FxSheetEnterState extends State<_FxSheetEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade);
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
