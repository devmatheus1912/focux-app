import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/batch_mutation_notice.dart';

void main() {
  test('tudo enviado: sucesso', () {
    expect(
      resolveBatchMutationNotice(failed: 0, queued: 0),
      BatchMutationNotice.success,
    );
  });

  test('algum item ficou na fila: aviso de pendente, nunca sucesso', () {
    expect(
      resolveBatchMutationNotice(failed: 0, queued: 2),
      BatchMutationNotice.queued,
    );
  });

  test('falha real prevalece sobre pendente', () {
    expect(
      resolveBatchMutationNotice(failed: 1, queued: 3),
      BatchMutationNotice.failure,
    );
  });
}
