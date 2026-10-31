import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/features/perfil/data/landing_studio_repository.dart';
import 'package:focux_app/features/perfil/screens/landing_editor_screen.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/providers/plano_features_provider.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/l10n/app_localizations.dart';

import '../../support/riverpod_seeds.dart';

class _Repo extends LandingStudioRepository {
  _Repo() : super(Dio());

  @override
  Future<LandingStudioState> getState() async =>
      LandingStudioState.fromJson(const {});
}

void main() {
  testWidgets('cada etapa da entrevista mostra seus campos', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          landingStudioRepositoryProvider.overrideWithValue(_Repo()),
          planoFeaturesProvider.overrideWith(
            () => SeededPlanoFeaturesNotifier(
              const AsyncData(
                PlanoFeatures(
                  plano: SubscriptionPlan.ENTERPRISE,
                  financeiro: true,
                  agenda: true,
                  relatorios: true,
                  whiteLabel: true,
                  iaCopiloto: true,
                  migracaoFoto: true,
                  landingCompleta: true,
                ),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: const LandingEditorScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final campos = find.byType(EditableText);
    await tester.enterText(campos.at(0), 'Marca');
    await tester.enterText(campos.at(1), 'Nicho');
    await tester.enterText(campos.at(2), 'Promessa');
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(S.of(tester.element(find.byType(Scaffold).first)).landingPorQueConfiarEmVoce), findsOneWidget);
    expect(find.byType(EditableText), findsWidgets);
  });
}
