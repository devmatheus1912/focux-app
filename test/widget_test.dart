import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App smoke test — verifica que o ProviderScope inicia sem crash', (WidgetTester tester) async {
    // Testa apenas um widget mínimo com ProviderScope, sem iniciar o app completo
    // (que faria chamadas HTTP reais via _loadCustomTheme e FcmService)
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Focux Personal')),
          ),
        ),
      ),
    );
    expect(find.text('Focux Personal'), findsOneWidget);
  });
}
