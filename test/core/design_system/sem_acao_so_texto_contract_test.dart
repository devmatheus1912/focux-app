import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regra do app: nenhuma ação é só texto. Toda ação tem superfície (botão
/// primário, `FxTonalButton`, linha ou botão de ícone). Este teste varre as
/// pastas já migradas e cresce a cada onda (ver `SPEC-execucao-treino.md`, M8).
const _pastasMigradas = [
  'lib/features/checkin',
  'lib/features/treinos',
  'lib/features/exercicios',
  'lib/features/alunos',
];

/// Exceções documentadas: arquivo → motivo.
const _excecoes = <String, String>{};

void main() {
  test('pastas migradas não usam TextButton como ação', () {
    final achados = <String>[];
    for (final pasta in _pastasMigradas) {
      for (final f in Directory(pasta).listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final caminho = f.path.replaceAll(r'\', '/');
        if (_excecoes.containsKey(caminho)) continue;
        final linhas = f.readAsLinesSync();
        for (var i = 0; i < linhas.length; i++) {
          if (RegExp(r'\bTextButton\b').hasMatch(linhas[i])) {
            achados.add('$caminho:${i + 1}');
          }
        }
      }
    }
    expect(
      achados,
      isEmpty,
      reason:
          'Use FxLiquidPrimaryButton, FxTonalButton ou botão de ícone. '
          'Achados: ${achados.join(', ')}',
    );
  });
}
