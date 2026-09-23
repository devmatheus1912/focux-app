import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_copilot_prescription.dart';
import 'package:focux_app/core/theme/brand_palette.dart';

void main() {
  testWidgets('Texto completo expands truncated prescription', (tester) async {
    const longAction =
        'Retomar contato com Beatriz e checar como está o treino, '
        'alinhar expectativas da semana e revisar aderência nos últimos dias.';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: Aluno360CopilotPrescription(
              title: 'Prioridade do dia',
              action: longAction,
              reason: 'Priorize contato.',
              color: BrandPalette.defaultPrimary,
              showTitle: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Texto completo'), findsOneWidget);

    await tester.tap(find.text('Texto completo'));
    await tester.pump();

    expect(find.text('Ocultar'), findsOneWidget);
    expect(find.text(longAction), findsOneWidget);
    expect(find.text('Texto completo'), findsNothing);
  });

  testWidgets('reason footer stacks segments on narrow width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: Aluno360CopilotPrescription(
              title: 'Prioridade do dia',
              action: 'Retomar contato.',
              reason: 'Priorize contato · sem registro recente · aderência 0%',
              color: BrandPalette.defaultPrimary,
              showTitle: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Priorize contato'), findsOneWidget);
    expect(find.text('sem registro recente'), findsOneWidget);
    expect(find.text('aderência 0%'), findsOneWidget);
  });

  testWidgets(
    'refreshingAi keeps deterministic action visible without skeleton overlay',
    (tester) async {
      final aluno = Aluno(
        id: 7,
        nome: 'Nathalia Abrantes',
        email: 'n@test.com',
        status: 'ATIVO',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Aluno360CopilotPrescriptionBody(
              aluno: aluno,
              primary: BrandPalette.defaultPrimary,
              fallback: 'Fallback',
              seed360: const {
                'acao':
                    'Retomar contato com Nathalia e checar como está o treino.',
                'motivo': 'Sem check-in recente',
                'fonte': 'RADAR',
              },
              forceIa: true,
              iaAsync: const AsyncValue.loading(),
              resumoLoading: false,
              iaRefreshing: true,
              onPrepareMessage: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.textContaining('Retomar contato com Nathalia'),
        findsWidgets,
      );
      expect(find.text('Preparar mensagem'), findsOneWidget);
      expect(find.byType(Aluno360CopilotPrescriptionLoading), findsNothing);
    },
  );
}
