import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Um bloco de cor por arquivo de tela: cor em todo card vira ruído.
void main() {
  test('no máximo um bloco de marca por tela', () {
    final repetidos = <String>[];
    final arquivos = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final arquivo in arquivos) {
      final n = 'marca: true'.allMatches(arquivo.readAsStringSync()).length;
      if (n > 1) repetidos.add('${arquivo.path}: $n');
    }
    expect(repetidos, isEmpty);
  });
}
