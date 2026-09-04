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

  test('pagina expõe hasNext e pesos newest-first viram série cronológica', () {
    final p0 = avaliacoesPaginaFromResponse({
      'content': [
        {'id': 3, 'pesoKg': 78.0},
        {'id': 2, 'pesoKg': 79.0},
        {'id': 1},
      ],
      'hasNext': true,
    });
    expect(p0.hasNext, isTrue);
    expect(p0.content, hasLength(3));

    final p1 = avaliacoesPaginaFromResponse({
      'content': [
        {'id': 0, 'pesoKg': 80.0},
      ],
      'hasNext': false,
    });
    expect(
      pesosHistoricoFromPaginas([p0, p1], maxPontos: 7),
      [80.0, 79.0, 78.0],
    );
    expect(
      pesosHistoricoFromPaginas([p0], maxPontos: 2),
      [79.0, 78.0],
    );
  });
}
