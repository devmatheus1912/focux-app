import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('modo presencial removido do app', () {
    expect(
      File('lib/features/checkin/screens/modo_presencial_screen.dart')
          .existsSync(),
      isFalse,
    );
    final body = File(
      'lib/features/treinos/screens/treino_detail_screen_body.part.dart',
    ).readAsStringSync();
    expect(body, isNot(contains('Modo presencial')));
  });
}
