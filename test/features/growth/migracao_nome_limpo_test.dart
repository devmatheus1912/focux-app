import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/growth/utils/migracao_nome_limpo.dart';

void main() {
  group('limparNome (mesmos casos do backend)', () {
    test('cada caso do arquivo compartilhado dá a mesma saída do Java', () {
      final casos = jsonDecode(
        File('test/features/growth/fixtures/limpeza_nome.json').readAsStringSync(),
      ) as List<dynamic>;
      expect(casos.length, greaterThan(10));
      for (final c in casos.cast<Map<String, dynamic>>()) {
        final limpo = limparNome(c['entrada'] as String);
        expect(limpo.nome, c['nome'], reason: "nome de '${c['entrada']}'");
        expect(limpo.objetivo, c['objetivo'], reason: "objetivo de '${c['entrada']}'");
      }
    });

    test('o arquivo do app é igual ao do backend', () {
      final backend = File(
        '../focux-backend/src/test/resources/migracao/limpeza_nome.json',
      );
      if (!backend.existsSync()) return; // CI do app roda sem o backend ao lado.
      expect(
        jsonDecode(File('test/features/growth/fixtures/limpeza_nome.json').readAsStringSync()),
        jsonDecode(backend.readAsStringSync()),
      );
    });

    test('nulo vira vazio', () {
      expect(limparNome(null).nome, isEmpty);
    });
  });
}
