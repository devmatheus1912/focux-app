import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

/// Garante o fio FE→BE: PATCH de prescrição passa pelo interceptor que
/// injeta Idempotency-Key (filtro global no backend).
void main() {
  test('PATCH de prescrição usa Dio e o ApiClient cobre PATCH com idempotency', () {
    final apiClient = File('lib/core/api/api_client.dart').readAsStringSync();
    final repository = readScreenSourceBundle(
      'lib/features/treinos/data/treino_repository.dart',
    );

    expect(apiClient, contains("options.headers['Idempotency-Key']"));
    expect(apiClient, contains("normalized == 'PATCH'"));
    expect(repository, contains('atualizarExercicioPrescricao'));
    expect(repository, contains('_dio.patch('));
    expect(repository, contains('/api/treinos/\$treinoId/exercicios/\$itemId'));
  });
}
