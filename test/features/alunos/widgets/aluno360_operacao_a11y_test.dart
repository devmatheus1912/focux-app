import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_operacao_focus_toggle.dart';
import 'package:focux_app/features/ia/data/ia_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Aluno360OperacaoFocusModeToggle TalkBack labels', () {
    testWidgets('icon-only toggle exposes activate label when focus off', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alunoOperacaoFocusModeProvider(42).overrideWith(
              (ref) => AlunoOperacaoFocusModeController(42),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Aluno360OperacaoFocusModeToggle(
                alunoId: 42,
                primary: Colors.teal,
                iconOnly: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(Aluno360OperacaoFocusModeToggle)),
        matchesSemantics(
          isButton: true,
          label:
              'Ativar modo foco — mostra só follow-up e copiloto',
        ),
      );
    });

    testWidgets('icon-only toggle exposes deactivate label when focus on', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alunoOperacaoFocusModeProvider(42).overrideWith((ref) {
              final c = AlunoOperacaoFocusModeController(42);
              c.state = true;
              return c;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Aluno360OperacaoFocusModeToggle(
                alunoId: 42,
                primary: Colors.teal,
                iconOnly: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(Aluno360OperacaoFocusModeToggle)),
        matchesSemantics(isButton: true, label: 'Desativar modo foco'),
      );
    });
  });

  test('ExecutarAcaoResponse parses backend payload', () {
    final resp = ExecutarAcaoResponse.fromJson({
      'tipoAcao': 'REDUZIR_CARGA',
      'status': 'OK',
      'mensagem': 'Cargas reduzidas em 3 exercícios.',
      'exerciciosAjustados': 3,
    });
    expect(resp.ok, isTrue);
    expect(resp.exerciciosAjustados, 3);
    expect(resp.mensagem, contains('3 exercícios'));
  });
}
