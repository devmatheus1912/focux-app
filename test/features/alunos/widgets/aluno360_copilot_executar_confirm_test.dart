import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_copilot_logic.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_copilot_executar_confirm.dart';
import 'package:focux_app/core/theme/brand_palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('copilotExecutarConfirmBody', () {
    test('REDUZIR_CARGA mentions carga reduction', () {
      expect(copilotExecutarConfirmBody('REDUZIR_CARGA'), contains('15%'));
    });

    test('ENVIAR_PUSH mentions notificação', () {
      expect(copilotExecutarConfirmBody('ENVIAR_PUSH'), contains('notificação'));
    });

    test('MARCAR_RISCO mentions contato prioritário', () {
      expect(
        copilotExecutarConfirmBody('MARCAR_RISCO'),
        contains('contato prioritário'),
      );
    });
  });

  testWidgets('confirm sheet shows tipo-specific body and cancel aborts', (
    tester,
  ) async {
    const spec = CopilotExecutarAcaoSpec(
      backendTipo: 'ENVIAR_PUSH',
      label: 'Enviar notificação ao aluno',
      icon: Icons.notifications_active_outlined,
      executingLabel: 'Enviando…',
      executingSemantics: 'Enviando notificação ao aluno',
      parametros: 'Oi, Beatriz.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showCopilotExecutarConfirmSheet(
                      context,
                      spec: spec,
                      primary: BrandPalette.defaultPrimary,
                    );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Enviar notificação ao aluno'), findsOneWidget);
    expect(find.textContaining('notificação ao aluno'), findsWidgets);
    expect(find.text('Oi, Beatriz.'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Enviar notificação ao aluno'), findsNothing);
  });
}
