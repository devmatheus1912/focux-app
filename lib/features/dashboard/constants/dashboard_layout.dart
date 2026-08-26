import 'package:flutter/material.dart';

import '../../../core/platform/focux_platform.dart';
import '../../../core/theme/tokens_strip.dart';

/// Tokens de layout do hub personal (grade 8pt, largura desktop).
abstract final class DashboardLayout {
  DashboardLayout._();

  static const double compactWidth = 390;
  static const double comfortableWidth = 600;
  /// Folga extra no fim do scroll. O [MainShell] já aplica
  /// `FxDock.shellClearance` — aqui só respiração de conteúdo,
  /// não um segundo “dock fantasma”.
  static const double bottomDockClearance = 24;
  /// Folga no fim do scroll quando o chip sticky fica acima do dock.
  /// Chip ~44 + padding 8 + folga para não cobrir o CTA do catálogo.
  static const double prioritiesOverlayReserve = 104;
  static const double touchTarget = 48;
  static const double commandCardPad = TokensStrip.s3; // 12
  static const double commandModuleGap = TokensStrip.s3;

  static const double screenPadding = TokensStrip.s4;
  static const double sectionGap = TokensStrip.s4;
  /// Folga entre cards do fold (Olá → ativação → Foco → ações).
  static const EdgeInsets foldCard = EdgeInsets.fromLTRB(
    TokensStrip.s4,
    0,
    TokensStrip.s4,
    TokensStrip.s4,
  );
  static const EdgeInsets foldFirst = EdgeInsets.fromLTRB(
    TokensStrip.s4,
    TokensStrip.s2,
    TokensStrip.s4,
    TokensStrip.s4,
  );
  static const double sliverSectionGap = TokensStrip.s2;
  static const double sliverTightGap = TokensStrip.s1;
  static const double headerIconGap = TokensStrip.s2;
  static const double headerIconGapDense = 4;
  static const double headerActionCompact = 44;
  static const double headerActionComfort = 48;
  static const double maxContentWidth = FocuxPlatform.desktopMaxContent;

  static bool isCompact(double width) => width < compactWidth;

  static bool isComfortable(double width) => width >= comfortableWidth;

  static double headerActionSize(double width) =>
      width < 430 ? headerActionCompact : headerActionComfort;

  static double headerChromeGap({required bool focusMode, required bool compact}) {
    if (compact) return headerIconGapDense;
    return headerIconGap;
  }

  static const EdgeInsets sectionPadding = EdgeInsets.fromLTRB(
    TokensStrip.s4,
    TokensStrip.s2,
    TokensStrip.s4,
    TokensStrip.s4,
  );
}
