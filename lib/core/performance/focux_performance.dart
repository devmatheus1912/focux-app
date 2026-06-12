/// Catálogo de performance percebida — loading, motion e transições.
abstract final class FocuxPerformance {
  FocuxPerformance._();

  static const String version = '1.0.0';

  static const List<String> coreSources = [
    'lib/core/performance/focux_performance.dart',
    'lib/core/utils/motion_preferences.dart',
    'lib/core/router/fx_page_transition.dart',
    'lib/core/widgets/fx_motion.dart',
    'lib/core/widgets/skeleton_loader.dart',
    'lib/core/widgets/fx_loading.dart',
  ];

  static const List<String> hubLoadingWidgets = [
    'lib/features/dashboard/widgets/dashboard_shimmer_loading.dart',
    'lib/features/alunos/widgets/aluno_detail_loading_skeleton.dart',
    'lib/features/ia/widgets/ia_copilot_insight_widgets.dart',
  ];

  static const List<String> hubLoadingPatterns = [
    'SkeletonList',
    'SkeletonLoader',
    'DashboardShimmer',
    'FxLoading',
    'AlunoDetailLoadingSkeleton',
    'IaCopilotInsightsLoading',
    'sectionShimmer',
    'Shimmer.fromColors',
  ];

  static const List<String> hubMotionPatterns = [
    'reduceMotionOf',
    'prefersReducedMotion',
    'FxStaggerItem',
    'fxTransitionPage',
    'fxMotionDuration',
  ];

  static const List<String> automatedGates = [
    'test/core/design_system/screen_tier_s_plus_contract_test.dart',
    'test/core/design_system/perceived_performance_pillar_contract_test.dart',
  ];
}
