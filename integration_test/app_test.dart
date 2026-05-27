import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:focux_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Splash ou login carrega sem crash', (tester) async {
    app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    final hasLogin = find.text('Entrar').evaluate().isNotEmpty;
    final hasSplash = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;

    expect(hasLogin || hasSplash, isTrue,
        reason: 'App deve mostrar login ou splash inicial');
  });
}
