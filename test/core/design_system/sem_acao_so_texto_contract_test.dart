import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regra do app: nenhuma ação é só texto. Toda ação tem superfície (botão
/// primário, `FxTonalButton`, linha ou botão de ícone). Este teste varre
/// todo `lib/` (ondas 1 a 4 do M8 em `SPEC-execucao-treino.md`).
const _pastasMigradas = ['lib'];

/// Exceções documentadas: arquivo -> motivo.
const _excecoes = <String, String>{
  'lib/core/theme/app_theme.dart':
      'define o tema padrão do Material (textButtonTheme); não é uma ação',
};

void main() {
  test('o app inteiro não usa TextButton como ação', () {
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
