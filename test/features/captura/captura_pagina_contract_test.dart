import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/pagina.dart';
import 'package:focux_app/features/captura/data/captura_repository.dart';
import 'package:focux_app/features/feed/data/feed_repository.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('captura meus parses Pagina envelope, not root List', () {
    final repo = readScreenSourceBundle(
      'lib/features/captura/data/captura_repository.dart',
    );
    expect(repo, contains('Pagina.fromJson'));
    expect(repo, contains("'/api/captura'"));
    expect(repo, contains('GET /api/captura devolve Pagina'));
    expect(repo, contains('queryParameters'));
    expect(repo, isNot(contains('r.data as List')));
  });

  test('Pagina maps captura content items', () {
    final pagina = Pagina.fromJson(
      {
        'content': [
          {
            'id': 1,
            'nome': 'Ana',
            'convertido': false,
            'criadoEm': '2026-09-01',
          },
        ],
        'hasNext': false,
        'nextCursor': null,
      },
      (item) => SubmissaoCaptura.fromJson(item as Map<String, dynamic>),
    );
    expect(pagina.content, hasLength(1));
    expect(pagina.content.first.nome, 'Ana');
  });

  test('Pagina maps feed content items', () {
    final pagina = Pagina.fromJson(
      {
        'content': [
          {
            'id': 7,
            'titulo': 'Treino',
            'conteudo': 'Hidratem-se',
            'criadoEm': '2026-09-01',
          },
        ],
        'hasNext': true,
        'nextCursor': 'abc',
      },
      (item) => FeedPost.fromJson(item as Map<String, dynamic>),
    );
    expect(pagina.content.single.titulo, 'Treino');
    expect(pagina.hasNext, isTrue);
    expect(pagina.nextCursor, 'abc');
  });
}
