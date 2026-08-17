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

Widget _onboardingApp({GoRouter? router}) {
  if (router != null) {
    return MaterialApp.router(
      theme: AppTheme.buildDarkTheme(TokensStrip.neonGlow),
      routerConfig: router,
    );
  }
  return MaterialApp(
    theme: AppTheme.buildDarkTheme(TokensStrip.neonGlow),
    home: OnboardingScreen(socialProofLoader: _emptyPulse),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding exibe toggle personal/aluno e primeiro slide', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_onboardingApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text(FocuxBrandCopy.onboardingExistingAccountCta), findsOneWidget);
    expect(find.text(FocuxBrandCopy.onboardingCtaNext), findsOneWidget);
    expect(find.text(FocuxBrandCopy.onboardingPersonaPersonal), findsOneWidget);
    expect(find.text(FocuxBrandCopy.onboardingPersonaAluno), findsOneWidget);

    await tester.tap(find.text(FocuxBrandCopy.onboardingPersonaAluno));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.textContaining('Execute com timer'), findsOneWidget);
  });

  testWidgets('trocar persona mantém o slide atual', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setSurface(tester, const Size(430, 932));

    await tester.pumpWidget(_onboardingApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.textContaining('Centro de Comando'), findsOneWidget);
    // Slide 1: hero budget — sem metric chips nem checklist.
    expect(find.text('360°'), findsNothing);
    expect(find.textContaining('Modos Treino'), findsNothing);

    await tester.tap(find.text(FocuxBrandCopy.onboardingCtaNext));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.textContaining('Mensalidades com PIX'),
      findsOneWidget,
    );

    await tester.tap(find.text(FocuxBrandCopy.onboardingPersonaAluno));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Form check'), findsOneWidget);
    expect(find.textContaining('Mensalidades com PIX'), findsNothing);
    expect(find.textContaining('Centro de Comando'), findsNothing);
    expect(
      find.text(FocuxBrandCopy.onboardingCtaFinishAluno),
      findsOneWidget,
    );
  });

  testWidgets('Já tenho conta marca onboarding e navega para login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setSurface(tester, const Size(430, 932));

    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder:
              (context, state) =>
                  OnboardingScreen(socialProofLoader: _emptyPulse),
        ),
        GoRoute(
          path: '/login',
          builder:
              (context, state) =>
                  const Scaffold(body: Center(child: Text('LOGIN_SCREEN'))),
        ),
      ],
    );

    await tester.pumpWidget(_onboardingApp(router: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    await tester.tap(find.text(FocuxBrandCopy.onboardingExistingAccountCta));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('LOGIN_SCREEN'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_done_v3'), isTrue);
  });

  testWidgets('Pular marca onboarding e navega para login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _setSurface(tester, const Size(430, 932));

    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder:
              (context, state) =>
                  OnboardingScreen(socialProofLoader: _emptyPulse),
        ),
        GoRoute(
          path: '/login',
          builder:
              (context, state) =>
                  const Scaffold(body: Center(child: Text('LOGIN_SCREEN'))),
        ),
      ],
    );

    await tester.pumpWidget(_onboardingApp(router: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    await tester.tap(find.text(FocuxBrandCopy.onboardingSkip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('LOGIN_SCREEN'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_done_v3'), isTrue);
  });

  testWidgets('slide 1 sem metric chips (hero budget Home)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    _setSurface(tester, const Size(430, 932));

    await tester.pumpWidget(_onboardingApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('360°'), findsNothing);
    expect(find.text('Ao vivo'), findsNothing);
    expect(find.textContaining('Centro de Comando'), findsOneWidget);
    expect(find.text(FocuxBrandCopy.onboardingSocialProofFallback), findsOneWidget);
  });
}
