import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/data_viz/focux_data_viz.dart';

void main() {
  test('FocuxDataViz catalog lists visualization types', () {
    expect(FocuxDataViz.vizSparkline, 'sparkline');
    expect(FocuxDataViz.vizBar, 'bar');
    expect(FocuxDataViz.vizDonut, 'donut');
    expect(FocuxDataViz.vizRing, 'ring');
    expect(FocuxDataViz.version, isNotEmpty);
  });

  test('ensureRenderableSeries duplicates single non-zero point', () {
    expect(FocuxDataViz.ensureRenderableSeries(const []), isEmpty);
    expect(
      FocuxDataViz.ensureRenderableSeries(const [0, 3, 0]),
      [3.0, 3.0],
    );
    expect(
      FocuxDataViz.ensureRenderableSeries(const [1, 2, 3]),
      [1.0, 2.0, 3.0],
    );
  });

  test('data viz sources and sparkline widget exist', () {
    for (final path in FocuxDataViz.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }

    final sparkline =
        File('lib/core/widgets/fx_sparkline.dart').readAsStringSync();
    expect(sparkline, contains('FxSparkline'));
    expect(sparkline, contains('CustomPaint'));

    final chartTheme =
        File('lib/core/theme/fx_chart_theme.dart').readAsStringSync();
    expect(chartTheme, contains('donutPalette'));
  });

  test('dashboard sparkline helpers derive series from domain data', () {
    final helpers =
        File('lib/features/dashboard/utils/dashboard_sparkline_helpers.dart')
            .readAsStringSync();
    expect(helpers, contains('dashboardCheckinsSparklineUltimos7Dias'));
    expect(helpers, contains('dashboardReceitaSparklineMensal'));
    expect(helpers, contains('List<double>'));
  });
}
