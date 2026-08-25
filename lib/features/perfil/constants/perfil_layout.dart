import '../../../core/theme/fx_settings_layout.dart';

/// Tokens de layout do hub Perfil — paridade [DashboardLayout] no sticky.
abstract final class PerfilLayout {
  PerfilLayout._();

  static const double stickyRevealScrollOffset = 120;
  static const double stickyOverlayReserve = 88;
  static const double stickyBottomInset = 8;
  static const double stickyRowHeight = 44;

  static const double sectionGapQuiet = FxSettingsLayout.groupGap;
  static const double sectionGapPrimary = FxSettingsLayout.groupGap;
}
