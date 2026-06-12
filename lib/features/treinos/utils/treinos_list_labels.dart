/// Rótulos plurais da lista de treinos — lógica pura fora da UI.
abstract final class TreinosListLabels {
  TreinosListLabels._();

  static String readyPlans(int count) =>
      count == 1 ? '1 plano pronto para uso.' : '$count planos prontos para uso.';

  static String readyCount(int count) =>
      count == 1 ? '1 pronto' : '$count prontos';

  static String templateCount(int count) =>
      count == 1 ? '1 template' : '$count templates';
}
