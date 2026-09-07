import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('galeria listar parse Pagina, not root List', () {
    final repo = readScreenSourceBundle(
      'lib/features/galeria/data/galeria_repository.dart',
    );
    expect(repo, contains('Pagina.fromJson'));
    expect(repo, contains('GET /api/personal/gallery devolve Pagina'));
    expect(repo, isNot(contains('r.data as List')));
  });
}
