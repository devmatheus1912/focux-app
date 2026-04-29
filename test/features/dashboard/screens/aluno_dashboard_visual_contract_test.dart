import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('student autonomy center keeps compact mobile layouts safe', () {
    final screen = File(
      'lib/features/dashboard/screens/aluno_dashboard_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('class _NextBestTaskPanel'));
    expect(screen, contains('final compact = constraints.maxWidth < 390'));
    expect(screen, contains('SizedBox(width: double.infinity, child: action)'));
    expect(screen, contains('maxLines: 3'));
    expect(screen, contains('class _AutonomyTaskTile'));
    expect(screen, contains('final compact = constraints.maxWidth < 360'));
    expect(screen, contains('BoxConstraints(maxWidth: 180)'));
    expect(screen, contains('BoxConstraints(maxWidth: 132)'));
  });
}
