/// Consistência semanal do aluno — só o que o plano realmente declara.
///
/// Contar fichas atribuídas e fazer `clamp(3, 6)` inventava meta de 3 dias
/// para qualquer rotina com 1–2 treinos. Sem frequência explícita, não há meta.
int? alunoWeeklyDayGoal({int? frequenciaDias}) {
  if (frequenciaDias == null || frequenciaDias < 1) return null;
  return frequenciaDias.clamp(1, 7);
}
