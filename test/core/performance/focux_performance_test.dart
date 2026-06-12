import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/performance/focux_performance.dart';

void main() {
  test('FocuxPerformance catalog lists core sources', () {
    for (final path in FocuxPerformance.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    expect(FocuxPerformance.version, isNotEmpty);
  });

  test('loading widgets respect reduced motion helpers', () {
    final skeleton = File('lib/core/widgets/skeleton_loader.dart').readAsStringSync();
    expect(skeleton, contains('reduceMotionOf'));

    final dashboardShimmer =
        File('lib/features/dashboard/widgets/dashboard_shimmer_loading.dart')
            .readAsStringSync();
    expect(dashboardShimmer, contains('reduceMotionOf'));

    final fxLoading = File('lib/core/widgets/fx_loading.dart').readAsStringSync();
    expect(fxLoading, contains('reduceMotionOf'));
  });

  test('page transitions skip animation when reduced motion', () {
    final source =
        File('lib/core/router/fx_page_transition.dart').readAsStringSync();
    expect(source, contains('reduceMotionOf'));
    expect(source, contains('return child'));
  });

  test('FxStaggerItem defers to reduceMotionOf', () {
    final source = File('lib/core/widgets/fx_motion.dart').readAsStringSync();
    expect(source, contains('reduceMotionOf'));
  });
}
