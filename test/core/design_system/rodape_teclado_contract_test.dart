import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Rodapé dentro do corpo não soma o teclado: o Scaffold já encolhe o corpo,
/// e somar de novo sobe o rodapé o dobro (bug do Ajustar cargas, build 226).
/// Só o rodapé em `bottomNavigationBar` (FxFormStickyBar) soma.
void main() {
  test('rodapé com "s3 + teclado" só no FxFormStickyBar e em bottomNavigationBar', () {
    const permitidos = {
      'lib/core/widgets/fx_form_chrome.dart',
      // `bottom` da anamnese vai para bottomNavigationBar.
      'lib/features/anamnese/screens/anamnese_screen.dart',
    };
    final achados = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final caminho = f.path.replaceAll(r'\', '/');
      if (permitidos.contains(caminho)) continue;
      if (f
          .readAsStringSync()
          .contains('TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom')) {
        achados.add(caminho);
      }
    }
    expect(achados, isEmpty);
  });

  test('Ajustar cargas: rodapé em bottomNavigationBar', () {
    final src =
        File('lib/features/ia/screens/ia_progressao_screen.dart')
            .readAsStringSync();
    expect(src, contains('bottomNavigationBar: FxFormStickyBar('));
  });
}
