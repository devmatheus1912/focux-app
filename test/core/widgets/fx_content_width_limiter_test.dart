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

  testWidgets(
    'limiter no bottom bar nao come a altura do body (paywall Planos)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Planos')),
            body: const SizedBox.expand(
              child: FxContentWidthLimiter(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: Text('Escolha o plano')),
                    SliverToBoxAdapter(child: Text('Premium')),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: const FxContentWidthLimiter(
              expandHeight: false,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Continuar no FREE'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Escolha o plano'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);

      final bodyTop = tester.getTopLeft(find.text('Escolha o plano')).dy;
      final stickyTop = tester.getTopLeft(find.text('Continuar no FREE')).dy;
      expect(bodyTop, lessThan(stickyTop));
      expect(tester.getSize(find.text('Escolha o plano')).height, greaterThan(0));
    },
  );
}
