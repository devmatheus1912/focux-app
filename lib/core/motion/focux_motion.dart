import 'package:flutter/animation.dart';

/// Catálogo de motion design — durações, curvas e widgets Fx.
abstract final class FocuxMotion {
  FocuxMotion._();

  static const String version = '1.0.0';

  static const int uiTransitionMs = 220;
  static const int staggerDelayMs = 60;
  static const int listEntranceMs = 400;
  static const int pageTransitionMs = 320;
  static const int pageReverseTransitionMs = 260;
  static const int glowPulseMs = 2400;

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve listEntranceCurve = Curves.easeOut;
  static const Curve pageCurve = Curves.easeOutCubic;

  static const List<String> coreSources = [
    'lib/core/motion/focux_motion.dart',
    'lib/core/utils/motion_preferences.dart',
    'lib/core/widgets/fx_motion.dart',
    'lib/core/router/fx_page_transition.dart',
    'lib/features/dashboard/utils/dashboard_entry_motion.dart',
  ];

  static const List<String> motionWidgets = [
    'FxStaggerItem',
    'FxSpringButton',
    'FxInteractiveGlow',
    'FxLiquidPrimaryButton',
  ];

  static const List<String> hubMotionPatterns = [
    'reduceMotionOf',
    'prefersReducedMotion',
    'fxMotionDuration',
    'FxStaggerItem',
    'FxSpringButton',
    'FxLiquidPrimaryButton',
    'FxInteractiveGlow',
    'dashboardEntryMotion',
    'fx_motion.dart',
    'fxTransitionPage',
  ];

  static const List<String> automatedGates = [
    'test/core/performance/motion_preferences_test.dart',
    'test/core/design_system/motion_design_pillar_contract_test.dart',
  ];
}
