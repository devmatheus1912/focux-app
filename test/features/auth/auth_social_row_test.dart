import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/widgets/apple_sign_in_button.dart';
import 'package:focux_app/features/auth/widgets/auth_social_row.dart';
import 'package:focux_app/features/auth/widgets/google_sign_in_button.dart';

Widget _app({
  required bool apple,
  required bool google,
  double largura = 300,
  double escala = 1,
  VoidCallback? onApple,
  VoidCallback? onGoogle,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(escala)),
    child: Scaffold(
      body: Center(
        child: SizedBox(
          width: largura,
          child: AuthSocialRow(
            mostrarApple: apple,
            mostrarGoogle: google,
            carregandoApple: false,
            carregandoGoogle: false,
            onApple: onApple ?? () {},
            onGoogle: onGoogle ?? () {},
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('com os dois, ficam lado a lado e com a mesma altura', (
    tester,
  ) async {
    await tester.pumpWidget(_app(apple: true, google: true));
    final apple = tester.getRect(find.byType(AppleSignInButton));
    final google = tester.getRect(find.byType(GoogleSignInButton));
    expect(apple.top, google.top);
    expect(apple.height, google.height);
    expect(apple.width, closeTo(google.width, 0.5));
    expect(apple.right, lessThan(google.left));
    expect(find.text('Continuar com Apple'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);
  });

  testWidgets('com um só, ele ocupa a largura toda no tamanho normal', (
    tester,
  ) async {
    await tester.pumpWidget(_app(apple: true, google: false));
    expect(tester.getSize(find.byType(AppleSignInButton)).width, 300);
    expect(tester.getSize(find.byType(AppleSignInButton)).height, 52);
    expect(find.byType(GoogleSignInButton), findsNothing);
  });

  testWidgets('cada botão responde ao próprio toque', (tester) async {
    var apple = 0;
    var google = 0;
    await tester.pumpWidget(
      _app(
        apple: true,
        google: true,
        onApple: () => apple++,
        onGoogle: () => google++,
      ),
    );
    await tester.tap(find.byType(AppleSignInButton));
    await tester.tap(find.byType(GoogleSignInButton));
    expect(apple, 1);
    expect(google, 1);
  });

  for (final escala in [1.0, 1.6, 2.0]) {
    testWidgets('aguenta 280 dp e letra ${escala}x sem estourar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(apple: true, google: true, largura: 280, escala: escala),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
