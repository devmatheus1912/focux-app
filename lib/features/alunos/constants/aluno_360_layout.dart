import 'package:flutter/material.dart';

/// Layout tokens for Aluno 360 (hero, sticky CTA, scroll insets).
abstract final class Aluno360Layout {
  Aluno360Layout._();

  static const double stickyBarContentHeight = 64;

  static double heroExpandedHeight(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return 318 + ((textScale - 1) * 180).clamp(0.0, 280.0);
  }

  /// Bottom padding so Operação content clears the sticky CTA bar.
  static double operacaoScrollBottomReserve(BuildContext context) {
    return stickyBarContentHeight +
        MediaQuery.paddingOf(context).bottom +
        48;
  }
}
