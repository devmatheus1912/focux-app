import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/brand/brand_pulse.dart';
import 'package:focux_app/core/brand/focux_brand_copy.dart';
import 'package:focux_app/core/theme/app_theme.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<BrandSocialProofItem>> _emptyPulse() async => const [];

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

GoRouter _router() => GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder:
          (context, state) => OnboardingScreen(socialProofLoader: _emptyPulse),
    ),
    GoRoute(
      path: '/login',
      builder:
          (context, state) =>
              const Scaffold(body: Center(child: Text('LOGIN_SCREEN'))),
    ),
    GoRoute(
      path: '/register',
      builder:
          (context, state) =>
              const Scaffold(body: Center(child: Text('REGISTER_SCREEN'))),
    ),
    GoRoute(
      path: '/register/aluno',
      builder:
          (context, state) =>
              const Scaffold(body: Center(child: Text('REGISTER_ALUNO'))),
    ),
  ],
);

Widget _app(GoRouter router) => MaterialApp.router(
  theme: AppTheme.buildDarkTheme(TokensStrip.neonGlow),
  routerConfig: router,
);

Future<void> _abrir(WidgetTester tester, GoRouter router) async {
  SharedPreferences.setMockInitialValues({});
  _setSurface(tester, const Size(390, 844));
  await tester.pumpWidget(_app(router));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('personal: título, três benefícios e Começar grátis', (
    tester,
  ) async {
    await _abrir(tester, _router());
    expect(find.text('Seus alunos treinam. Você acompanha.'), findsOneWidget);
    for (final b in FocuxBrandCopy.onboardingBeneficios(
      OnboardingPersona.personal,
    )) {
      expect(find.text(b.texto), findsOneWidget);
    }
    expect(find.text(FocuxBrandCopy.onboardingCtaFinish), findsOneWidget);
    expect(find.text(FocuxBrandCopy.onboardingCtaFinishHint), findsOneWidget);
    expect(
      find.text(FocuxBrandCopy.onboardingSocialProofFallback),
      findsOneWidget,
    );
    // sem carrossel, sem "Pular" e sem "Quero isso"
    expect(find.byType(PageView), findsNothing);
    expect(find.text('Pular'), findsNothing);
  });

  testWidgets('escolher "Sou aluno" troca a tela inteira', (tester) async {
    await _abrir(tester, _router());
    await tester.tap(find.text(FocuxBrandCopy.onboardingSouAluno));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.text('Seu treino, do jeito que seu personal montou.'),
      findsOneWidget,
    );
    expect(find.text('Seus alunos treinam. Você acompanha.'), findsNothing);
    expect(find.text(FocuxBrandCopy.onboardingCtaFinishAluno), findsOneWidget);
    expect(
      find.text(FocuxBrandCopy.onboardingCtaFinishHintAluno),
      findsOneWidget,
    );
    expect(find.text(FocuxBrandCopy.onboardingCtaFinish), findsNothing);
  });

  testWidgets('Começar grátis marca o onboarding e vai ao cadastro', (
    tester,
  ) async {
    await _abrir(tester, _router());
    await tester.tap(find.text(FocuxBrandCopy.onboardingCtaFinish));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('REGISTER_SCREEN'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_done_v3'), isTrue);
  });

  testWidgets('Tenho um convite leva a ativar conta do aluno', (tester) async {
    await _abrir(tester, _router());
    await tester.tap(find.text(FocuxBrandCopy.onboardingSouAluno));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(FocuxBrandCopy.onboardingCtaFinishAluno));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('REGISTER_ALUNO'), findsOneWidget);
  });

  testWidgets('"Já tem conta? Entrar" marca o onboarding e vai ao login', (
    tester,
  ) async {
    await _abrir(tester, _router());
    await tester.tap(find.text(FocuxBrandCopy.authExistingAccountAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('LOGIN_SCREEN'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_done_v3'), isTrue);
  });

  for (final tela in [const Size(320, 640), const Size(390, 844)]) {
    testWidgets(
      'botão principal visível sem rolar em ${tela.width.toInt()}×${tela.height.toInt()}',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        _setSurface(tester, tela);
        await tester.pumpWidget(_app(_router()));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.text(FocuxBrandCopy.onboardingCtaFinish)).bottom,
          lessThanOrEqualTo(tela.height),
        );
      },
    );
  }
}
