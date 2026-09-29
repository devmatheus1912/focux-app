part of 'treino_repository.dart';

/// Edição dos exercícios de um treino.
extension TreinoRepositoryExercicios on TreinoRepository {
  Future<Treino> adicionarExercicio(
    int treinoId,
    int exercicioId, {
    int series = 3,
    String repeticoes = '10-12',
    int descanso = 60,
    double? cargaKg,
    int? rpeAlvo,
    String? observacoes,
    String tipoSerie = 'NORMAL',
    int? grupoSuperset,
    int? ordem,
  }) async {
    final response = await _dio.post(
      '/api/treinos/$treinoId/exercicios',
      data: {
        'exercicioId': exercicioId,
        'series': series,
        'repeticoes': repeticoes,
        'descansoSegundos': descanso,
        if (cargaKg != null) 'cargaKg': cargaKg,
        if (rpeAlvo != null) 'rpeAlvo': rpeAlvo,
        if (observacoes != null && observacoes.trim().isNotEmpty)
          'observacoes': observacoes.trim(),
        'tipoSerie': tipoSerie,
        if (grupoSuperset != null) 'grupoSuperset': grupoSuperset,
        if (ordem != null) 'ordem': ordem,
      },
    );
    throwIfQueuedOffline(response);
    return Treino.fromJson(response.data as Map<String, dynamic>);
  }

  /// Inclui antes de remover: falha real no meio mantém o antigo em vez de
  /// deixar o treino sem nenhum. Na fila, as duas seguem juntas e em ordem.
  Future<void> substituirExercicio(
    int treinoId,
    TreinoExercicioItem item,
    int novoExercicioId,
  ) async {
    var queued = false;
    try {
      await adicionarExercicio(
        treinoId,
        novoExercicioId,
        series: item.series,
        repeticoes: item.repeticoes,
        descanso: item.descansoSegundos ?? 60,
        cargaKg: item.cargaKg,
        rpeAlvo: item.rpeAlvo,
        observacoes: item.observacoes,
        tipoSerie: item.tipoSerie,
        grupoSuperset: item.grupoSuperset,
        ordem: item.ordem,
      );
    } on OfflineQueuedException {
      queued = true;
    }
    try {
      await removerExercicio(treinoId, item.id);
    } on OfflineQueuedException {
      queued = true;
    }
    if (queued) throw const OfflineQueuedException();
  }

  Future<void> removerExercicio(int treinoId, int itemId) async {
    throwIfQueuedOffline(
      await _dio.delete('/api/treinos/$treinoId/exercicios/$itemId'),
    );
  }

  Future<Treino> reordenarExercicios(int treinoId, List<int> itemIds) async {
    final response = await _dio.patch(
      '/api/treinos/$treinoId/exercicios/ordem',
      data: {'itemIds': itemIds},
    );
    return Treino.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Treino> atualizarExercicioPrescricao(
    int treinoId,
    int itemId, {
    required int series,
    required String repeticoes,
    required int descansoSegundos,
    double? cargaKg,
    int? rpeAlvo,
    String? observacoes,
    required String tipoSerie,
    int? grupoSuperset,
  }) async {
    final response = await _dio.patch(
      '/api/treinos/$treinoId/exercicios/$itemId',
      data: {
        'series': series,
        'repeticoes': repeticoes,
        'descansoSegundos': descansoSegundos,
        'cargaKg': cargaKg,
        'rpeAlvo': rpeAlvo,
        'observacoes': observacoes?.trim(),
        'tipoSerie': tipoSerie,
        if (tipoSerie == 'SUPERSET' && grupoSuperset != null)
          'grupoSuperset': grupoSuperset,
      },
    );
    return Treino.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Treino> duplicarExercicio(int treinoId, int itemId) async {
    final response = await _dio.post(
      '/api/treinos/$treinoId/exercicios/$itemId/duplicar',
    );
    throwIfQueuedOffline(response);
    return Treino.fromJson(response.data as Map<String, dynamic>);
  }
}
