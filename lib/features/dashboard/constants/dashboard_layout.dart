import 'package:flutter/material.dart';

import '../../../core/platform/focux_platform.dart';
import '../../../core/theme/tokens_strip.dart';

/// Tokens de layout do hub personal (grade 8pt, largura desktop).
abstract final class DashboardLayout {
  DashboardLayout._();

  static const double screenPadding = TokensStrip.s4;
  static const double sectionGap = TokensStrip.s4;
  static const double sliverSectionGap = TokensStrip.s2;
  static const double sliverTightGap = TokensStrip.s1;
  static const double headerIconGap = TokensStrip.s2;
  static const double maxContentWidth = FocuxPlatform.desktopMaxContent;

  static const EdgeInsets sectionPadding = EdgeInsets.fromLTRB(
    TokensStrip.s4,
    TokensStrip.s2,
    TokensStrip.s4,
    TokensStrip.s4,
  );
}
