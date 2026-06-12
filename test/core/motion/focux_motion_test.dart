import 'dart:io';

import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/motion/focux_motion.dart';

void main() {
  test('FocuxMotion catalog lists canonical durations and curves', () {
    expect(FocuxMotion.uiTransitionMs, 220);
    expect(FocuxMotion.staggerDelayMs, 60);
    expect(FocuxMotion.listEntranceMs, 400);
    expect(FocuxMotion.standardCurve, Curves.easeOutCubic);
    expect(FocuxMotion.version, isNotEmpty);
  });

  test('motion sources and widgets exist', () {
    for (final path in FocuxMotion.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }

    final fxMotion = File('lib/core/widgets/fx_motion.dart').readAsStringSync();
    for (final widget in FocuxMotion.motionWidgets) {
      expect(fxMotion, contains(widget), reason: 'Widget ausente: $widget');
    }
  });

  test('motion widgets respect reduced motion helpers', () {
    final fxMotion = File('lib/core/widgets/fx_motion.dart').readAsStringSync();
    expect(fxMotion, contains('reduceMotionOf'));
    expect(fxMotion, contains('prefersReducedMotion'));

    final pageTransition =
        File('lib/core/router/fx_page_transition.dart').readAsStringSync();
    expect(pageTransition, contains('reduceMotionOf'));

    final dashboardMotion =
        File('lib/features/dashboard/utils/dashboard_entry_motion.dart')
            .readAsStringSync();
    expect(dashboardMotion, contains('prefersReducedMotion'));
  });
}
