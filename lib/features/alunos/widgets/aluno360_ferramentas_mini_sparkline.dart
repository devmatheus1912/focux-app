import 'package:flutter/material.dart';

import '../../../core/widgets/fx_sparkline.dart';

/// Compact weekly trend for Ferramentas module tiles (e.g. Aderência).
class Aluno360FerramentasMiniSparkline extends StatelessWidget {
  const Aluno360FerramentasMiniSparkline({
    super.key,
    required this.data,
    required this.color,
    required this.semanticsLabel,
  });

  final List<double> data;
  final Color color;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSignal = data.any((v) => v > 0);
    final plotData =
        hasSignal
            ? data
            : List<double>.filled(data.isEmpty ? 5 : data.length, 0.14);
    final strokeColor =
        hasSignal ? color : color.withValues(alpha: isDark ? 0.62 : 0.48);
    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(left: 2, top: 1),
          child: FxSparkline(
            data: plotData,
            color: strokeColor,
            width: 52,
            height: 22,
            strokeWidth: hasSignal ? 2.0 : 2.2,
            fill: false,
          ),
        ),
      ),
    );
  }
}
