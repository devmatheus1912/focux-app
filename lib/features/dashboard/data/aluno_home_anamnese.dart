/// Anamnese que pede ação do aluno, vinda do BFF (`anamnesePendente`).
/// Só o status: o conteúdo da ficha fica em `/aluno/anamnese`.
enum AlunoAnamnesePendente {
  solicitada,
  precisaAtestado;

  static AlunoAnamnesePendente? tryParse(Object? raw) => switch (raw) {
    'SOLICITADA' => solicitada,
    'PRECISA_ATESTADO' => precisaAtestado,
    _ => null,
  };
}
