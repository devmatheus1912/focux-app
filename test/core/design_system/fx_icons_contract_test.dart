import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/fx_icons.dart';

/// Ícone do app é Phosphor, por significado, em `FxIcons`. `Icons.*` ou
/// `CupertinoIcons.*` direto numa tela volta a misturar traços (rounded,
/// outlined) e desenhos de outra família.
void main() {
  test('Icons e CupertinoIcons só em fx_icons.dart', () {
    final uso = RegExp(r'(?<![A-Za-z])(Cupertino)?Icons\.[a-z]');
    final falhas = <String>[];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.replaceAll(r'\', '/');
      final norm = path.substring(path.indexOf('lib/'));
      if (norm == 'lib/core/theme/fx_icons.dart') continue;
      final linhas = file.readAsLinesSync();
      for (final (i, linha) in linhas.indexed) {
        final codigo = linha.split('//').first;
        if (uso.hasMatch(codigo)) falhas.add('$norm:${i + 1}');
      }
    }
    expect(falhas, isEmpty, reason: 'Use FxIcons (lib/core/theme/fx_icons.dart).');
  });

  test('FxIcons é Phosphor', () {
    expect(FxIcons.fechar.fontFamily, 'PhosphorLight');
    expect(FxIcons.fecharPequeno.fontFamily, 'PhosphorRegular');
    expect(FxIcons.concluidoAtivo.fontFamily, 'PhosphorFill');
  });
}
