import 'package:flutter/material.dart';

import '../../../core/platform/focux_platform.dart';
import '../../../core/theme/tokens_strip.dart';

/// Chrome da lista de treinos — paridade Home / Alunos.
abstract final class TreinosLayout {
  TreinosLayout._();

  static const double headerChromeSize = 36;
  static const double headerChromeGap = 3;
  static const double compactChromeWidth = 360;

  static bool isCompactChrome(double width) => width < compactChromeWidth;

  static const double screenPadding = TokensStrip.s4;
  static const double touchTarget = 48;
  static const double listItemGap = 10;
  static const double listBottomGapComfort = 36;
  static const double listBottomGapCompact = 28;
  static const double bulkBarPaddingBottom = 12;

  static double listBottomGap(BuildContext context) =>
      FocuxPlatform.isCompact(context)
          ? listBottomGapCompact
          : listBottomGapComfort;
}
