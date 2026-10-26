import 'package:flutter/material.dart';

import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/fx_premium_entrance.dart';

/// Staggered entrance wrapper for Operação sections.
class Aluno360OperacaoEntrance extends StatefulWidget {
  const Aluno360OperacaoEntrance({
    super.key,
    required this.enabled,
    required this.delay,
    required this.child,
    this.onPlayed,
  });

  final bool enabled;
  final Duration delay;
  final Widget child;
  final VoidCallback? onPlayed;

  @override
  State<Aluno360OperacaoEntrance> createState() =>
      _Aluno360OperacaoEntranceState();
}

class _Aluno360OperacaoEntranceState extends State<Aluno360OperacaoEntrance> {
  var _played = false;

  @override
  Widget build(BuildContext context) {
    if (!_played && widget.enabled && widget.onPlayed != null) {
      _played = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPlayed?.call();
      });
    }
    if (!widget.enabled || reduceMotionOf(context)) return widget.child;
    return ClipRect(
      child: FxPremiumEntrance(delay: widget.delay, child: widget.child),
    );
  }
}
