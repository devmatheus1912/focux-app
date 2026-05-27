import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/brand/focux_brand_copy.dart';
import 'package:focux_app/core/theme/app_theme.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding exibe toggle personal/aluno e primeiro slide', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildDarkTheme(TokensStrip.neonGlow),
        home: const OnboardingScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text(FocuxBrandCopy.onboardingExistingAccountCta), findsOneWidget);
    expect(find.text(FocuxBrandCopy.onboardingCtaNext), findsOneWidget);

    await tester.tap(find.text('Aluno'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.textContaining('Execute com timer'), findsOneWidget);
  });

  testWidgets('trocar persona mantém o slide atual', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildDarkTheme(TokensStrip.neonGlow),
        home: const OnboardingScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.textContaining('Command Center'), findsOneWidget);

    await tester.tap(find.text(FocuxBrandCopy.onboardingCtaNext));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.textContaining('Mensalidades com PIX'),
      findsOneWidget,
    );

    await tester.tap(find.text('Aluno'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Form check'), findsOneWidget);
    expect(find.textContaining('Mensalidades com PIX'), findsNothing);
    expect(find.textContaining('Command Center'), findsNothing);
  });

  testWidgets('Já tenho conta marca onboarding e navega para login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('LOGIN_SCREEN')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.buildDarkTheme(TokensStrip.neonGlow),
        routerConfig: router,
      ),
    );
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
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('LOGIN_SCREEN')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.buildDarkTheme(TokensStrip.neonGlow),
        routerConfig: router,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    await tester.tap(find.text(FocuxBrandCopy.onboardingSkip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('LOGIN_SCREEN'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_done_v3'), isTrue);
  });
}
