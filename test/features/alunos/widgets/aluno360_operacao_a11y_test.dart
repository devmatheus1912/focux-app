import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/widgets/aluno_operacao_adherence_legend.dart';
import 'package:focux_app/features/ia/data/ia_repository.dart';
import 'package:focux_app/core/theme/brand_palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlunoOperacaoAdherenceLegend', () {
    testWidgets('exposes combined semantics label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlunoOperacaoAdherenceLegend(
              activeColor: Colors.green,
              missColor: Colors.red,
              todayRingColor: BrandPalette.defaultPrimary,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(AlunoOperacaoAdherenceLegend)),
        matchesSemantics(
          label: 'Legenda: treinou, faltou, sem treino previsto, hoje',
        ),
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
