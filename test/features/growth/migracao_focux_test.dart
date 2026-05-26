import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/widgets/mesh_scope.dart';
import 'package:focux_app/features/growth/screens/migracao_magica_screen.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/providers/plano_features_provider.dart';

void main() {
  test('migracao focux usa polish 10/10 e copy alinhada', () {
    final screen = File(
      'lib/features/growth/screens/migracao_magica_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('Migração Focux'));
    expect(screen, contains('Importe alunos com IA'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('prefersReducedMotion'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('Importar arquivo'));
    expect(screen, contains('MigracaoFileParser'));
    expect(screen, contains('_editarAluno'));
    expect(screen, contains('_mostrarResumoImportacao'));
    expect(screen, contains('Nenhum aluno identificado'));
    expect(screen, contains('/api/v1/migracao/preview'));
    expect(screen, contains('Já cadastrado'));
    expect(screen, contains('Planilha estruturada'));
    expect(screen, isNot(contains('Migração Mágica')));
    expect(screen, isNot(contains('Sem upload de arquivo')));
  });

  testWidgets('migracao focux pump com import e revisao', (tester) async {
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
                  ..state = const AsyncData(PlanoFeatures.optimisticEnterprise),
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

    expect(find.text('Migração Focux'), findsOneWidget);
    expect(find.text('Importe alunos com IA'), findsOneWidget);
    expect(find.text('Iniciar migração'), findsOneWidget);
    expect(find.text('Importar arquivo'), findsOneWidget);
    expect(find.text('Colar texto'), findsOneWidget);
    expect(find.textContaining('Planilha estruturada'), findsOneWidget);
  });
}
