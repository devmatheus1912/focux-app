import 'package:flutter/material.dart';

import '../../../core/platform/focux_platform.dart';
import '../../../core/theme/tokens_strip.dart';

/// Tokens de layout do hub Alunos — paridade Home / Perfil.
abstract final class AlunosLayout {
  AlunosLayout._();

  static const double headerChromeSize = 36;

  /// Paridade Home `_chromeGap`.
  static const double headerChromeGap = 3;

  /// Home some busca abaixo de 360; aqui some o toggle de tema.
  static const double compactChromeWidth = 360;

  static bool isCompactChrome(double width) => width < compactChromeWidth;

  static const double touchTarget = 48;

  static const double sectionGap = TokensStrip.s3;

  static const double chipGlowStrength = 0.04;

  static const double screenPadding = TokensStrip.s4;

  static const double searchBarRadius = 17;

  static const EdgeInsets searchBarPadding = EdgeInsets.fromLTRB(13, 3, 8, 3);

  static const EdgeInsets searchBarOuterPadding = EdgeInsets.symmetric(
    horizontal: screenPadding,
    vertical: 6,
  );

  static const EdgeInsets filterRowPadding = EdgeInsets.fromLTRB(
    screenPadding,
    4,
    0,
    10,
  );

  /// Folga no fim da row para o último chip não ficar sob o fade.
  static const double filterRowEndInset = 28;

  static const double cardPadding = 14;

  static const double cardPaddingCompact = 9;

  static const double cardAvatarGap = 12;

  static const double cardAvatarGapCompact = 10;

  static const double listItemGap = 10;

  static const double listItemGapCompact = 8;

  static const double listGapTop = TokensStrip.s2;

  static const double bulkBarPaddingBottom = 12;

  static const double listBottomGapComfort = 36;

  static const double listBottomGapCompact = 28;

  static double listBottomGap(BuildContext context) =>
      FocuxPlatform.isCompact(context)
          ? listBottomGapCompact
          : listBottomGapComfort;

  static const double formBottomBarHeight = 48;

  static const double formScrollBottom = 96;
}
