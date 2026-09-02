import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/pagina.dart';

void main() {
  test('envelope offset: content, page, size, totalElements, hasNext', () {
    final pagina = Pagina.fromJson(
      {
        'content': [
          {'id': 1},
          {'id': 2},
        ],
        'page': 0,
        'size': 20,
        'totalElements': 137,
        'hasNext': true,
      },
      (item) => (item as Map)['id'] as int,
    );

    expect(pagina.content, [1, 2]);
    expect(pagina.page, 0);
    expect(pagina.size, 20);
    expect(pagina.totalElements, 137);
    expect(pagina.hasNext, isTrue);
    expect(pagina.isOffset, isTrue);
    expect(pagina.isCursor, isFalse);
    expect(pagina.nextCursor, isNull);
  });

  test('envelope cursor: content, nextCursor, hasNext — sem page', () {
    final pagina = Pagina.fromJson(
      {
        'content': [
          {'id': 9},
        ],
        'nextCursor': 'eyJpZCI6MTIzfQ',
        'hasNext': true,
      },
      (item) => (item as Map)['id'] as int,
    );

    expect(pagina.content, [9]);
    expect(pagina.nextCursor, 'eyJpZCI6MTIzfQ');
    expect(pagina.hasNext, isTrue);
    expect(pagina.isCursor, isTrue);
    expect(pagina.isOffset, isFalse);
    expect(pagina.page, isNull);
    expect(pagina.totalElements, isNull);
  });

  test('hasNext ausente e false, nao derivado', () {
    // Sem o campo, o contrato manda tratar como fim — nunca inferir de size.
    final pagina = Pagina.fromJson(
      {
        'content': [1, 2, 3],
        'page': 0,
        'size': 3,
        'totalElements': 3,
      },
      (item) => item as int,
    );

    expect(pagina.hasNext, isFalse);
  });

  test('totalElements pode faltar no offset (§1.4)', () {
    final pagina = Pagina.fromJson(
      {
        'content': [1],
        'page': 2,
        'size': 20,
        'hasNext': true,
      },
      (item) => item as int,
    );

    expect(pagina.totalElements, isNull);
    expect(pagina.hasNext, isTrue);
    expect(pagina.isOffset, isTrue);
  });

  test('array em items em vez de content falha alto', () {
    // E o quinto formato. O chat legado (items/nextBeforeId/hasMore) nao
    // passa por este parser — se passou, o endpoint novo copiou o legado.
    expect(
      () => Pagina.fromJson(
        {
          'items': [1],
          'nextBeforeId': 12,
          'hasMore': true,
        },
        (item) => item as int,
      ),
      throwsFormatException,
    );
  });

  test('Page cru do Spring nao preenche page nem hasNext', () {
    // number/last sao ignorados. Sem hasNext o app trata como fim — devolver
    // Page<T> direto e o quinto formato silencioso que o wrapper existe para
    // impedir. O teste trava esse sintoma, nao um parse explosivo.
    final pagina = Pagina.fromJson(
      {
        'content': [1],
        'number': 0,
        'size': 20,
        'totalElements': 100,
        'last': false,
      },
      (item) => item as int,
    );
    expect(pagina.hasNext, isFalse);
    expect(pagina.page, isNull);
    expect(pagina.size, 20);
    expect(pagina.totalElements, 100);
  });
}
