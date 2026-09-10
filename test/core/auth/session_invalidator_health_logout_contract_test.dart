import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('logout limpa health grant e widget de recuperacao', () {
    final invalidator = File(
      'lib/core/auth/session_invalidator.dart',
    ).readAsStringSync();
    expect(invalidator, contains('HealthService.revokeAccess'));
    expect(invalidator, contains('HomeWidgetService.clear'));
    expect(invalidator, contains('_clearHealthSession'));

    final widget = File(
      'lib/core/health/home_widget_service.dart',
    ).readAsStringSync();
    expect(widget, contains('static Future<void> clear()'));
    expect(widget, contains("recoveryLabel: ''"));
    expect(widget, contains('steps: 0'));
  });
}
