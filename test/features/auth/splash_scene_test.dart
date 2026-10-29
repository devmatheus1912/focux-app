import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/app_theme.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/focux_official_logo.dart';
import 'package:focux_app/features/auth/utils/splash_navigation.dart';
import 'package:focux_app/features/auth/widgets/splash_scene.dart';

Future<void> _pump(
  WidgetTester tester,
  SplashEstado estado, {
  VoidCallback? onTentar,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.buildDarkTheme(TokensStrip.neonGlow),
      home: Scaffold(
        body: SplashScene(
          estado: estado,
          fadeOut: const AlwaysStoppedAnimation(1.0),
          onTentarNovamente: onTentar,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('resolvendo: só o logo, sem barra nem "Carregando"', (
    tester,
  ) async {
    await _pump(tester, SplashEstado.resolvendo);
    expect(find.byType(FocuxOfficialLogo), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('CARREGANDO'), findsNothing);
    expect(find.textContaining('Carregando'), findsNothing);
    expect(find.text('Tentar de novo'), findsNothing);
  });

  testWidgets('demorando: aparece a barra fina, sem texto', (tester) async {
    await _pump(tester, SplashEstado.demorando);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Tentar de novo'), findsNothing);
  });

  testWidgets('travada: mensagem e "Tentar de novo" funcionam', (tester) async {
    var tocou = 0;
    await _pump(tester, SplashEstado.travada, onTentar: () => tocou++);
    expect(find.text('Está demorando mais que o normal…'), findsOneWidget);
    await tester.tap(find.text('Tentar de novo'));
    expect(tocou, 1);
  });

  test('a cena não tem controladores em loop nem percentual', () {
    final src =
        File('lib/features/auth/widgets/splash_scene.dart').readAsStringSync();
    expect(src, isNot(contains('repeat(')));
    expect(src, isNot(contains('por cento')));
    expect(src, isNot(contains('AnimationController')));
  });
}
