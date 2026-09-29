/// Aviso único ao fim de uma mutação em lote.
enum BatchMutationNotice { success, queued, failure, failureWithQueued }

/// Falha real vence: o usuário precisa refazer algo — e, se parte do lote só
/// entrou na fila offline, o erro diz isso também. Sem falha, qualquer item
/// na fila impede o "concluído".
BatchMutationNotice resolveBatchMutationNotice({
  required int failed,
  required int queued,
}) {
  if (failed > 0) {
    return queued > 0
        ? BatchMutationNotice.failureWithQueued
        : BatchMutationNotice.failure;
  }
  if (queued > 0) return BatchMutationNotice.queued;
  return BatchMutationNotice.success;
}
