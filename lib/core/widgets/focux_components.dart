/// Catálogo canônico de componentes Fx — fonte única para gates de consistência.
abstract final class FocuxComponents {
  FocuxComponents._();

  static const String version = '1.0.0';

  /// Componentes obrigatórios em hubs S+.
  static const List<String> hubPatterns = [
    'fxScreenA11yScope',
    'FxShellScaffold',
    'FxShellAppBar',
    'FxHubHeader',
    'FxLoading',
    'FxEmptyState',
    'FxErrorState',
    'FxAsyncBody',
    'FeedbackHelper',
    'fxListTileCardShell',
    'FxSatelliteListTile',
    'showFxBottomSheet',
    'showFxHomeSheet',
    'showFxInsetPickerSheet',
    'FxInsetPickerOption',
    'FxContentWidthLimiter',
    'SkeletonLoader',
    'DashboardShimmer',
    'AlunoDetailLoadingSkeleton',
  ];

  /// Arquivos do catálogo Fx em `lib/core/widgets/`.
  static const List<String> catalogPaths = [
    'lib/core/widgets/fx_loading.dart',
    'lib/core/widgets/fx_empty_state.dart',
    'lib/core/widgets/fx_error_state.dart',
    'lib/core/widgets/fx_async_body.dart',
    'lib/core/widgets/fx_hub_header.dart',
    'lib/core/widgets/fx_shell_scaffold.dart',
    'lib/core/widgets/fx_input_deco.dart',
    'lib/core/widgets/fx_content_width_limiter.dart',
    'lib/core/widgets/fx_screen_a11y.dart',
    'lib/core/widgets/fx_bottom_sheet.dart',
    'lib/core/widgets/fx_home_sheet.dart',
    'lib/core/widgets/fx_inset_picker_sheet.dart',
    'lib/core/widgets/fx_inset_picker_option.dart',
    'lib/core/widgets/feedback_helper.dart',
    'lib/core/widgets/fx_glass_surface.dart',
    'lib/core/widgets/fx_motion.dart',
    'lib/core/widgets/fx_horizontal_scroll_peek.dart',
    'lib/core/widgets/fx_icon.dart',
    'lib/core/widgets/fx_dock.dart',
    'lib/core/widgets/fx_connectivity_banner.dart',
    'lib/core/widgets/fx_celebration_overlay.dart',
  ];

  static const int minimumFxWidgets = 15;
}
