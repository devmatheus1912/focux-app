import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// O que fica velho depois de um check-in mora em `checkinSessaoMudou`.
/// Tela ou widget do check-in que limpa cache à mão volta a espalhar a regra:
/// uma quarta escrita esqueceria um cache e mostraria dado velho.
void main() {
  test('check-in só invalida caches por checkinSessaoMudou', () {
    const dono = 'lib/features/checkin/providers/checkin_provider.dart';
    final failures = <String>[];
    for (final file in Directory('lib/features/checkin')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.replaceAll(r'\', '/');
      final norm = path.substring(path.indexOf('lib/'));
      if (norm == dono) continue;
      final source = file.readAsStringSync();
      for (final proibido in const [
        'EvolucaoHomeClientCache.clear()',
        'Aluno360ClientCache.clear()',
      ]) {
        if (source.contains(proibido)) failures.add('$norm: $proibido');
      }
    }
    expect(failures, isEmpty, reason: 'Use checkinSessaoMudou(ref).');
  });
}
