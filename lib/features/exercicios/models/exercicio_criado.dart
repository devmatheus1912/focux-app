/// Para onde o personal quer ir depois de criar um exercício.
enum ExercicioCriadoDestino {
  /// Só fecha; o exercício ficou em "Meus exercícios".
  ficar,

  /// Abre "Meus exercícios" na biblioteca.
  verEmMeus,

  /// Veio de "Adicionar exercício": entra no treino aberto.
  adicionarAoTreino,

  /// Veio de "Trocar por similar" ou da prescrição: ocupa o lugar do atual.
  usarNoLugar,

  /// Abre o cadastro de novo.
  criarOutro,
}

/// Resultado de `/exercicios/novo`: o exercício criado e o que fazer com ele.
class ExercicioCriado {
  const ExercicioCriado({
    required this.id,
    required this.nome,
    this.destino = ExercicioCriadoDestino.ficar,
  });

  final int id;
  final String nome;
  final ExercicioCriadoDestino destino;
}

/// De onde o cadastro foi aberto; decide as opções da folha de confirmação.
enum ExercicioOrigem { biblioteca, treino, troca }

ExercicioOrigem exercicioOrigemDe(String? valor) => switch (valor) {
  'treino' => ExercicioOrigem.treino,
  'troca' => ExercicioOrigem.troca,
  _ => ExercicioOrigem.biblioteca,
};
