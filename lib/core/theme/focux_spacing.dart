import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'tokens_strip.dart';

/// Espaçamento e radius da grade 8pt — fonte única fora das features.
abstract final class FocuxSpacing {
  FocuxSpacing._();

  static const double screenHorizontal = TokensStrip.s4;
  static const double screenVertical = TokensStrip.s4;
  static const double section = TokensStrip.s4;
  static const double card = TokensStrip.s4;

  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: TokensStrip.s4,
    vertical: TokensStrip.s4,
  );

  static const EdgeInsets screenHorizontalOnly = EdgeInsets.symmetric(
    horizontal: TokensStrip.s4,
  );

  static EdgeInsets fromLTRB({
    double left = TokensStrip.s4,
    double top = TokensStrip.s4,
    double right = TokensStrip.s4,
    double bottom = TokensStrip.s4,
  }) =>
      EdgeInsets.fromLTRB(left, top, right, bottom);

  static SizedBox gapH(double step) => SizedBox(width: step);
  static SizedBox gapV(double step) => SizedBox(height: step);

  static SizedBox get gapXsH => gapH(TokensStrip.s1);
  static SizedBox get gapSmH => gapH(TokensStrip.s2);
  static SizedBox get gapMdH => gapH(TokensStrip.s3);
  static SizedBox get gapXsV => gapV(TokensStrip.s1);
  static SizedBox get gapSmV => gapV(TokensStrip.s2);
  static SizedBox get gapMdV => gapV(TokensStrip.s3);
  static SizedBox get gapLgV => gapV(TokensStrip.s5);

  static BorderRadius cardRadius = BorderRadius.circular(TokensStrip.rCard);
  static BorderRadius inputRadius = BorderRadius.circular(TokensStrip.rInput);
  static BorderRadius pillRadius = BorderRadius.circular(TokensStrip.rPill);

  static double radius(EagleRadius size) => switch (size) {
        EagleRadius.xs => EagleTokens.radiusXs,
        EagleRadius.sm => EagleTokens.radiusSm,
        EagleRadius.md => EagleTokens.radiusMd,
        EagleRadius.lg => EagleTokens.radiusLg,
        EagleRadius.xl => EagleTokens.radiusXl,
      };
}

enum EagleRadius { xs, sm, md, lg, xl }
