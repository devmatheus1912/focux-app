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

  test('falha real sem pendente: só o erro', () {
    expect(
      resolveBatchMutationNotice(failed: 1, queued: 0),
      BatchMutationNotice.failure,
    );
  });

  test('falha real com pendente: erro que também avisa a fila', () {
    expect(
      resolveBatchMutationNotice(failed: 1, queued: 3),
      BatchMutationNotice.failureWithQueued,
    );
  });
}
