import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/models/progressao_sugestao.dart';
import 'package:focux_app/features/ia/utils/progressao_copy.dart';

void main() {
  const ctx = ProgressaoContextoResumo(
    treinos: ['A'],
    exercicios: 14,
    exerciciosComHistorico: 10,
    sessoes4Semanas: 5,
  );

  test('a frase muda com o tempo e usa os números do contexto', () {
    expect(
      progressaoGerandoFrase(const Duration(seconds: 1), ctx),
      'Lendo os 5 treinos das últimas 4 semanas…',
    );
    expect(
      progressaoGerandoFrase(const Duration(seconds: 5), ctx),
      'Comparando as cargas de 14 exercícios…',
    );
    expect(
      progressaoGerandoFrase(const Duration(seconds: 12), ctx),
      startsWith('Quase pronto.'),
    );
    // Sem contexto: sem número inventado.
    expect(
      progressaoGerandoFrase(const Duration(seconds: 1), null),
      'Lendo os treinos recentes…',
    );
  });

  test('pedido em uma linha e o ✓ com plural', () {
    expect(
      progressaoPedidoLinha(
        objetivo: ProgressaoObjetivo.values.first,
        sinais: const [],
        observacao: '  joelho ',
      ),
      '${ProgressaoObjetivo.values.first.label} · “joelho”',
    );
    expect(progressaoProntas(1), '1 sugestão pronta');
    expect(progressaoProntas(3), '3 sugestões prontas');
  });
}
