import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_operacao_sticky_cta.dart';
import 'package:focux_app/features/alunos/widgets/aluno_operacao_adherence_legend.dart';
import 'package:focux_app/features/ia/data/ia_repository.dart';
import 'package:focux_app/core/theme/brand_palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Aluno360OperacaoStickyCtaBar TalkBack labels', () {
    testWidgets('sticky bar exposes operacao actions container label', (
      tester,
    ) async {
      final aluno = Aluno(
        id: 42,
        nome: 'Beatriz',
        email: 'b@test.com',
        status: 'ATIVO',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alunoOpenIaActionsProvider(42).overrideWith((ref) async => const []),
            alunoRecoveryProvider(42).overrideWith((ref) async => null),
            alunoCopilotoForceIaProvider(42).overrideWith((ref) => false),
            aluno360OperacaoProvider(42).overrideWith(
              (ref) => resolveAluno360OperacaoSnapshot(
                aluno: aluno,
                proximaAcao360: ProximaAcaoResumo(
                  acao: 'Retomar contato',
                  motivo: 'Sem check-ins',
                  fonte: 'PADRAO',
                  prioridade: 'P1',
                  tipoAcao: 'CONTATO',
                  mensagemSugerida: 'Oi, Beatriz.',
                ),
                forceIa: false,
                iaAsync: null,
                hasOpenTask: false,
                followUpDue: false,
                wearableRelevant: false,
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Aluno360OperacaoStickyCtaBar(
                aluno: aluno,
                alunoId: 42,
                proximaAcao360: ProximaAcaoResumo(
                  acao: 'Retomar contato',
                  motivo: 'Sem check-ins',
                  fonte: 'PADRAO',
                  prioridade: 'P1',
                  tipoAcao: 'CONTATO',
                  mensagemSugerida: 'Oi, Beatriz.',
                ),
                hasOpenCopilotTask360: false,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('aluno360_operacao_sticky_cta')), findsOneWidget);
      final semanticsNodes = tester.widgetList<Semantics>(find.byType(Semantics));
      expect(
        semanticsNodes.any(
          (node) =>
              node.properties.label == 'Ações rápidas da aba operação',
        ),
        isTrue,
      );
    });
  });

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
          label: 'Legenda: check-in, sem registro, hoje',
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
