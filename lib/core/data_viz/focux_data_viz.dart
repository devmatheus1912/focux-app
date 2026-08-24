/// Catálogo de data viz — séries, sparklines e conteúdo dinâmico nos hubs.
abstract final class FocuxDataViz {
  FocuxDataViz._();

  static const String version = '1.0.0';

  static const String vizSparkline = 'sparkline';
  static const String vizBar = 'bar';
  static const String vizDonut = 'donut';
  static const String vizRing = 'ring';

  static const List<String> coreSources = [
    'lib/core/data_viz/focux_data_viz.dart',
    'lib/core/widgets/fx_sparkline.dart',
    'lib/features/dashboard/utils/dashboard_sparkline_helpers.dart',
    'lib/features/alunos/utils/aluno360_evolucao_inteligente_logic.dart',
  ];

  static const List<String> hubDataVizPatterns = [
    'FxSparkline',
    'fl_chart',
    'CustomPaint',
    'sparkline',
    '.when(',
    'dashboard_sparkline_helpers',
    '_EvolucaoChart',
    'PieChart',
    'insightsProvider',
    'resolveVolumeSparklineData',
  ];

  static const List<String> automatedGates = [
    'test/core/design_system/data_viz_dynamic_content_pillar_contract_test.dart',
    'test/core/design_system/perceived_performance_pillar_contract_test.dart',
    'test/core/design_system/ux_feedback_pillar_contract_test.dart',
  ];

  /// Duplica ponto único para sparkline renderizar linha (mesma regra Aluno 360).
  static List<double> ensureRenderableSeries(List<double> values) {
    final nonZero = values.where((v) => v > 0).toList();
    if (nonZero.isEmpty) return const [];
    if (nonZero.length == 1) return [nonZero.first, nonZero.first];
    return values;
  }
}
