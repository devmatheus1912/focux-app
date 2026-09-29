/// `extra` das rotas `/treinos/novo`, `/treinos/:id` e
/// `/treinos/:id/exercicios/add` (Map para sobreviver ao go_router).
class TreinoRouteExtra {
  const TreinoRouteExtra({
    this.alunoId,
    this.alunoNome,
    this.recemCriado = false,
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
      recemCriado: extra['recemCriado'] == true,
    );
  }

  final int? alunoId;
  final String? alunoNome;

  /// Treino acabou de nascer no fluxo "Novo treino" desta sessão.
  final bool recemCriado;

  Map<String, Object>? toExtra() {
    if (alunoId == null && alunoNome == null && !recemCriado) return null;
    return {
      if (alunoId != null) 'alunoId': alunoId!,
      if (alunoNome != null) 'alunoNome': alunoNome!,
      if (recemCriado) 'recemCriado': true,
    };
  }
}

/// "Concluir" da montagem: treino novo sem aluno abre o detalhe (para atribuir);
/// vindo do Aluno 360 ou do detalhe, `null` = volta para a origem.
String? addExercicioConcluirDestino({
  required int treinoId,
  required bool recemCriado,
  int? alunoId,
}) {
  if (!recemCriado || alunoId != null) return null;
  return '/treinos/$treinoId';
}

/// "Atribuir a aluno" vira a ação primária só no treino recém-criado, com
/// exercícios e ainda sem aluno (o modelo não traz atribuições).
bool treinoDetailAtribuirEmDestaque({
  required bool recemCriado,
  required int? alunoId,
  required bool atribuido,
  required bool temExercicios,
}) =>
    recemCriado && alunoId == null && !atribuido && temExercicios;
