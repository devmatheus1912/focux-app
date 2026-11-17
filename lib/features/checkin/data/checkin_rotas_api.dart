/// Quem conduz a sessão e por onde ela fala com a API (SPEC-modo-presencial).
///
/// É o único lugar com os caminhos da execução: a execução, o repositório e a
/// fila sem internet só conhecem o canal. Cada ação do aluno tem o par do
/// personal; o backend testa a mesma tabela (`CheckinRotasContractTest`).
/// Outro jeito de conduzir (aula em grupo, por exemplo) é outra classe aqui, e
/// todo `switch` que esquecer o caso deixa de compilar.
sealed class CanalDoCheckin {
  const CanalDoCheckin();

  String get _base;

  /// Aluno do modo presencial; nulo no canal do aluno.
  int? get alunoId;

  String iniciar() => '$_base/iniciar';
  String serie(int execucaoId, int treinoExercicioId) =>
      '$_base/$execucaoId/exercicio/$treinoExercicioId/series';
  String exercicio(int execucaoId, int treinoExercicioId) =>
      '$_base/$execucaoId/exercicio/$treinoExercicioId';
  String confirmarRestante(int execucaoId, int treinoExercicioId) =>
      '$_base/$execucaoId/exercicio/$treinoExercicioId/confirmar-restante';
  String confirmarPlano() => '$_base/confirmar-plano';
  String concluir(int execucaoId) => '$_base/$execucaoId/concluir';
  String descartar(int execucaoId) => '$_base/$execucaoId/descartar';
  String detalhe(int execucaoId) => '$_base/$execucaoId';
  String evolucao(int execucaoId) => '$_base/$execucaoId/evolucao-sessao';

  /// Corpo de iniciar e "Já fiz": o presencial diz de qual aluno.
  Map<String, dynamic> corpoDoTreino(int treinoId) => {
    'treinoId': treinoId,
    if (alunoId != null) 'alunoId': alunoId,
  };
}

/// O aluno no app dele.
final class CanalDoAluno extends CanalDoCheckin {
  const CanalDoAluno();

  @override
  String get _base => '/api/checkin';

  @override
  int? get alunoId => null;
}

/// O personal conduzindo o treino do aluno no aparelho dele.
final class CanalPresencial extends CanalDoCheckin {
  const CanalPresencial(this.alunoId);

  @override
  final int alunoId;

  @override
  String get _base => '/api/checkin/personal';

  @override
  bool operator ==(Object other) => other is CanalPresencial && other.alunoId == alunoId;

  @override
  int get hashCode => alunoId.hashCode;
}

/// O canal salvo numa série da fila (`presencialAlunoId`); item antigo = aluno.
CanalDoCheckin canalDe(int? presencialAlunoId) =>
    presencialAlunoId == null ? const CanalDoAluno() : CanalPresencial(presencialAlunoId);
