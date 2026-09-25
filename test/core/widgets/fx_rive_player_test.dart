import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_rive_player.dart';

void main() {
  testWidgets('sem motor nativo do Rive mostra o fallback estático', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            FxRiveHeartPulse(),
            FxRiveBadgeGlow(size: 36, fallback: Text('badge-fallback')),
          ],
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.text('badge-fallback'), findsOneWidget);
  });
}
