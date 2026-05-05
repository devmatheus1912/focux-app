import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('command center autonomy bottlenecks keep compact layout safe', () {
    final widget =
        File(
          'lib/features/dashboard/screens/command_center_widget.dart',
        ).readAsStringSync();

    expect(widget, contains('class _AutonomiaGargaloTile'));
    expect(widget, contains('final compact = constraints.maxWidth < 360'));
    expect(widget, contains('IconButton.filledTonal'));
    expect(widget, contains('BoxConstraints(maxWidth: 150)'));
    expect(widget, contains('BoxConstraints(maxWidth: 52)'));
    expect(widget, contains('maxLines: 3'));
    expect(widget, contains('Expanded(child: copy)'));
    expect(widget, contains('class _FocuxRadarSection'));
    expect(widget, contains('class _AlunoScoreTile'));
    expect(widget, contains("'Radar Focux'"));
    expect(widget, contains('score.proximaAcao'));
    expect(widget, contains('score.risco'));
    expect(widget, contains('score.deltaScore'));
    expect(widget, contains('_deltaLabel'));
  });
}
