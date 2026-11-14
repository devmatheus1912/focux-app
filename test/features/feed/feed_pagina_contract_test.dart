import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/pagina.dart';
import 'package:focux_app/features/feed/data/feed_repository.dart';

void main() {
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
