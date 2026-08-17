import '../../../core/theme/tokens_strip.dart';

/// Tokens de layout do hub Perfil — paridade [DashboardLayout].
abstract final class PerfilLayout {
  PerfilLayout._();

  /// Chip flutuante + folga (menor que a Home: sem dock duplicado).
  static const double stickyOverlayReserve = 72;

  static const double stickyBottomInset = 8;

  static const double stickyRowHeight = 44;

  /// Secundário quiet (Operação, Conta, debug).
  static const double sectionGapQuiet = TokensStrip.s2;

  /// Blocos primários (Marca, prontidão).
  static const double sectionGapPrimary = TokensStrip.s3;

  static const double headerChromeSize = 36;

  static const double headerChromeGap = 3;
}
