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
}
