import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/platform/focux_platform.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';

/// Chrome da lista de treinos — paridade Home / Alunos.
abstract final class TreinosLayout {
  TreinosLayout._();

  static const double headerChromeSize = FxHelpChrome.iconSize;
  static const double headerChromeGap = FxHelpChrome.gap;

  static const double screenPadding = TokensStrip.s4;
  static const double touchTarget = FxHelpChrome.touchTarget;
  static const double listItemGap = 10;
  static const double exerciseRowPadH = 8;
  static const double exerciseRowPadV = 8;
  static const double exerciseGroupGap = 10;
  static const double listBottomGapComfort = 36;
  static const double listBottomGapCompact = 28;
  static const double bulkBarPaddingBottom = 12;

  static EdgeInsets homeSheetPadding(BuildContext context) {
    final media = MediaQuery.of(context);
    final dock = media.viewPadding.bottom;
    final keyboard = media.viewInsets.bottom;
    return EdgeInsets.fromLTRB(
      14,
      0,
      14,
      math.max(12, math.max(dock + 10, keyboard + 12)),
    );
  }

  static double listBottomGap(BuildContext context) =>
      FocuxPlatform.isCompact(context)
          ? listBottomGapCompact
          : listBottomGapComfort;
}
