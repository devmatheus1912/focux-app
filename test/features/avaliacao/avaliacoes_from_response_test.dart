import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/avaliacao/data/avaliacao_repository.dart';

void main() {
  test('avaliacoesFromResponse lê PaginaResponse.content', () {
    final list = avaliacoesFromResponse({
      'content': [
        {'id': 1, 'pesoKg': 80.0, 'avaliadoEm': '2026-01-01'},
        {'id': 2, 'pesoKg': 79.0, 'avaliadoEm': '2026-02-01'},
      ],
      'page': 0,
      'size': 100,
      'totalElements': 2,
      'hasNext': false,
    });
    expect(list, hasLength(2));
    expect(list.first.id, 1);
    expect(list.last.pesoKg, 79);
  });

  test('avaliacoesFromResponse aceita items, itens e lista crua', () {
    expect(
      avaliacoesFromResponse({
        'items': [
          {'id': 3, 'pesoKg': 70.0},
        ],
      }).single.id,
      3,
    );
    expect(
      avaliacoesFromResponse({
        'itens': [
          {'id': 4, 'pesoKg': 71.0},
        ],
      }).single.id,
      4,
    );
    expect(
      avaliacoesFromResponse([
        {'id': 5, 'pesoKg': 72.0},
      ]).single.id,
      5,
    );
    expect(avaliacoesFromResponse({'content': null}), isEmpty);
    expect(avaliacoesFromResponse(null), isEmpty);
  });
}
