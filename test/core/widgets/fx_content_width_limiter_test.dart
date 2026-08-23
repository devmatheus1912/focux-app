import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_content_width_limiter.dart';

void main() {
  testWidgets('com altura bounded, ListView recebe viewport e nao colapsa', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: FxContentWidthLimiter(
              maxWidth: 960,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: Text('PaywallHero')),
                  SliverToBoxAdapter(child: Text('Plano Premium')),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SizedBox(
            height: 72,
            child: Center(child: Text('Continuar no FREE')),
          ),
        ),
      ),
    );

    expect(find.text('PaywallHero'), findsOneWidget);
    expect(find.text('Plano Premium'), findsOneWidget);
    expect(find.text('Continuar no FREE'), findsOneWidget);

    final stickyTop = tester.getTopLeft(find.text('Continuar no FREE')).dy;
    final heroTop = tester.getTopLeft(find.text('PaywallHero')).dy;
    expect(heroTop, lessThan(stickyTop));
  });
}
