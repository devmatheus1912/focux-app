/// Cotas mensais de IA — espelham {@code PlanoLimites} no backend.
class PlanoIaLimits {
  PlanoIaLimits._();

  static const pro = 200;
  static const enterprise = 600;
}

/// Teto de alunos ativos — espelha {@code PlanoLimites} no backend.
class PlanoAlunosLimits {
  PlanoAlunosLimits._();

  static const pro = 30;
}
