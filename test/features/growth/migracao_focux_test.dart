import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/widgets/mesh_scope.dart';
import 'package:focux_app/features/growth/screens/migracao_magica_screen.dart';
import 'package:focux_app/features/growth/utils/migracao_foto_limits.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/providers/plano_features_provider.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('migracao focux usa OCR local e limites de foto', () {
    final screen = File(
      'lib/features/growth/screens/migracao_magica_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('Migração Focux'));
    expect(screen, contains('MigracaoOcrService'));
    expect(screen, contains('MigracaoFotoLimits'));
    expect(screen, contains('_verificarAcessoFoto'));
    expect(screen, contains('/api/v1/migracao/foto/registrar'));
    expect(screen, isNot(contains('/api/v1/migracao/imagem')));
    expect(screen, contains('OCR gratuito'));
    expect(screen, contains('MFIT'));
    expect(screen, isNot(contains('Migração Mágica')));
  });

  testWidgets('migracao focux pump com OCR e quota copy', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planoFeaturesProvider.overrideWith(
            (ref) =>
                PlanoFeaturesNotifier(PlanosRepository(ApiClient()))
                  ..state = const AsyncData(
                    PlanoFeatures(
                      plano: SubscriptionPlan.PREMIUM,
                      financeiro: true,
                      agenda: true,
                      relatorios: true,
                      whiteLabel: false,
                      iaCopiloto: true,
                      migracaoFoto: true,
                      limiteMigracaoFotoMensal: MigracaoFotoLimits.premium,
                      migracaoFotosUsadasMes: 2,
                    ),
                  ),
          ),
        ],
        child: const MaterialApp(
          home: MeshScope(
            active: true,
            child: MigracaoMagicaScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Subir foto ou print'), findsOneWidget);
    expect(find.textContaining('OCR gratuito'), findsOneWidget);
    expect(find.textContaining('Fotos este mês'), findsOneWidget);
  });
}
