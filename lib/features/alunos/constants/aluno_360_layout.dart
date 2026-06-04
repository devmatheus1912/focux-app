import 'package:flutter/material.dart';

/// Layout tokens for Aluno 360 (hero, sticky CTA, scroll insets).
abstract final class Aluno360Layout {
  Aluno360Layout._();

  static const double stickyBarContentHeight = 64;

  /// Approximate hero card body (matches [AlunoDetailHeroCard] at textScale ≤ 1.25).
  static double heroBodyHeight(BuildContext context) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.25);
    return 118 + ((textScale - 1) * 36);
  }

  /// Toolbar inset + hero card + bottom padding — no dead gap above the card.
  static double heroExpandedHeight(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return top + kToolbarHeight + 2 + heroBodyHeight(context) + 6;
  }

  /// Bottom padding so Operação content clears the sticky CTA bar.
  static double operacaoScrollBottomReserve(BuildContext context) {
    return stickyBarContentHeight +
        MediaQuery.paddingOf(context).bottom +
        48;
  }
}
