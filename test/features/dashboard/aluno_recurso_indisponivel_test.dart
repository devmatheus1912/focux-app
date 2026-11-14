import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/widgets/aluno_recurso_indisponivel.dart';

void main() {
  test('o estado do aluno nunca fala de plano, preço ou upgrade', () {
    final src = File(
      'lib/features/dashboard/widgets/aluno_recurso_indisponivel.dart',
    ).readAsStringSync();
    // Só o texto entre aspas (comentários podem citar "plano").
    final textos = RegExp(r"'([^']*)'")
        .allMatches(src)
        .map((m) => m[1]!)
        .where((t) => !t.endsWith('.dart'));
    for (final t in textos) {
      final baixo = t.toLowerCase();
      for (final p in ['plano', 'upgrade', 'assin', 'r\$', ' pro', 'enterprise']) {
        expect(baixo.contains(p), isFalse, reason: '"$p" em "$t"');
      }
    }
  });

  test('texto curto para ação barrada', () {
    expect(
      alunoRecursoIndisponivelTexto('Hábitos', 'Matheus'),
      'Hábitos não está disponível. Fale com Matheus.',
    );
    expect(
      alunoRecursoIndisponivelTexto('Hábitos', null),
      'Hábitos não está disponível. Fale com seu personal.',
    );
  });

  test('o FeatureGate usa o estado novo para o aluno', () {
    final gate = File('lib/core/widgets/feature_gate.dart').readAsStringSync();
    expect(gate, contains('AlunoRecursoIndisponivel('));
    expect(gate, isNot(contains('ainda não liberou')));
  });
}
