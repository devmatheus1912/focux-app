import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_copilot_logic.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_copilot_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('executar button exposes label for TREINO spec', (tester) async {
    const spec = CopilotExecutarAcaoSpec(
      backendTipo: 'REDUZIR_CARGA',
      label: 'Aplicar ajuste de carga (−15%)',
      icon: Icons.fitness_center_rounded,
      executingLabel: 'Aplicando…',
      executingSemantics: 'Aplicando ajuste de carga',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Aluno360CopilotExecutarAcaoButton(
              alunoId: 7,
              spec: spec,
              primary: Colors.teal,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aplicar ajuste de carga (−15%)'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(Aluno360CopilotExecutarAcaoButton)),
      matchesSemantics(
        isButton: true,
        label: 'Aplicar ajuste de carga (−15%)',
      ),
    );
  });

  testWidgets('executar button exposes push label for ENVIAR_PUSH spec', (
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
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Aluno360CopilotExecutarAcaoButton(
              alunoId: 7,
              spec: spec,
              primary: Colors.teal,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enviar notificação ao aluno'), findsOneWidget);
  });
}
