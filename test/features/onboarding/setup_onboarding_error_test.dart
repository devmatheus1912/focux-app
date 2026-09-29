import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:focux_app/features/onboarding/screens/setup_onboarding_widget.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/providers/plano_features_provider.dart';
import 'package:focux_app/l10n/app_localizations.dart';

import '../../support/riverpod_seeds.dart';

void main() {
  testWidgets('falha do status de ativação mostra erro compacto com retry', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingStatusProvider.overrideWith((ref) async {
            calls++;
            throw Exception('boom interno');
          }),
          planoFeaturesProvider.overrideWith(
            () => SeededPlanoFeaturesNotifier(
              const AsyncLoading<PlanoFeatures>(),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: const Scaffold(body: SetupOnboardingWidget()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar sua ativação.'), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
    final antes = calls;

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(calls, greaterThan(antes));
  });

  testWidgets('gate de plano no status de ativação não mostra erro', (
    tester,
  ) async {
    final options = RequestOptions(path: '/api/onboarding/status');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingStatusProvider.overrideWith((ref) async {
            throw DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 403,
                data: {
                  'erro': 'Recurso do plano PRO.',
                  'codigo': 'PLANO_FEATURE_REQUER_UPGRADE',
                },
              ),
            );
          }),
          planoFeaturesProvider.overrideWith(
            () => SeededPlanoFeaturesNotifier(
              const AsyncLoading<PlanoFeatures>(),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: const Scaffold(body: SetupOnboardingWidget()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar sua ativação.'), findsNothing);
    expect(find.text('Tentar novamente'), findsNothing);
  });
}
