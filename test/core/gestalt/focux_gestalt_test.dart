import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/gestalt/focux_gestalt.dart';

void main() {
  test('FocuxGestalt catalog lists gestalt principles', () {
    expect(FocuxGestalt.principleProximity, 'proximity');
    expect(FocuxGestalt.principleSimilarity, 'similarity');
    expect(FocuxGestalt.principleContinuity, 'continuity');
    expect(FocuxGestalt.principleFigureGround, 'figure_ground');
    expect(FocuxGestalt.version, isNotEmpty);
  });

  test('gestalt sources and grouping widgets exist', () {
    for (final path in FocuxGestalt.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }

    final shell = File('lib/core/widgets/fx_shell_scaffold.dart').readAsStringSync();
    expect(shell, contains('fxListTileCardShell'));
    expect(shell, contains('fxListCardDecoration'));

    final peek =
        File('lib/core/widgets/fx_horizontal_scroll_peek.dart').readAsStringSync();
    expect(peek, contains('FxHorizontalScrollPeek'));
    expect(peek, contains('lightMeshC'));
  });

  test('section headers use shared layout tokens', () {
    final alunoHeader =
        File('lib/features/alunos/constants/aluno_360_layout.dart')
            .readAsStringSync();
    expect(alunoHeader, contains('Aluno360Layout'));
    expect(alunoHeader, contains('FxSettingsLayout.groupRadius'));

    final dashboardHelpers =
        File('lib/features/dashboard/utils/dashboard_screen_helpers.dart')
            .readAsStringSync();
    expect(dashboardHelpers, contains('dashboardSectionKickerStyle'));
  });
}
