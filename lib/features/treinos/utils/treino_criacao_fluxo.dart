/// `extra` das rotas `/treinos/:id` e
/// `/treinos/:id/exercicios/add` (Map para sobreviver ao go_router).
class TreinoRouteExtra {
  const TreinoRouteExtra({
    this.alunoId,
    this.alunoNome,
    this.bloco,
    this.modeloId,
  });

  factory TreinoRouteExtra.parse(Object? extra) {
    if (extra is! Map) return const TreinoRouteExtra();
    final rawAlunoId = extra['alunoId'];
    return TreinoRouteExtra(
      alunoId:
          rawAlunoId is int
              ? rawAlunoId
              : int.tryParse(rawAlunoId?.toString() ?? ''),
      alunoNome: extra['alunoNome']?.toString(),
      bloco: extra['bloco']?.toString(),
      modeloId:
          extra['modeloId'] is int
              ? extra['modeloId'] as int
              : int.tryParse(extra['modeloId']?.toString() ?? ''),
    );
  }

  final int? alunoId;
  final String? alunoNome;
  final String? bloco;

  /// Treino aberto a partir de um modelo de ficha (e não da ficha de um aluno).
  final int? modeloId;

  Map<String, Object>? toExtra() {
    if (alunoId == null &&
        alunoNome == null &&
        bloco == null &&
        modeloId == null) {
      return null;
    }
    return {
      if (alunoId != null) 'alunoId': alunoId!,
      if (alunoNome != null) 'alunoNome': alunoNome!,
      if (bloco != null) 'bloco': bloco!,
      if (modeloId != null) 'modeloId': modeloId!,
    };
  }
}
