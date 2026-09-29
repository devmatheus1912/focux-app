/// Aviso único ao fim de uma mutação em lote.
enum BatchMutationNotice { success, queued, failure }

/// Falha real vence: o usuário precisa refazer algo. Sem falha, qualquer item
/// que só entrou na fila offline impede o "concluído".
BatchMutationNotice resolveBatchMutationNotice({
  required int failed,
  required int queued,
}) {
  if (failed > 0) return BatchMutationNotice.failure;
  if (queued > 0) return BatchMutationNotice.queued;
  return BatchMutationNotice.success;
}
