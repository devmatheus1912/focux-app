/// Cotas mensais de IA — espelham {@code PlanoLimites} no backend.
class PlanoIaLimits {
  PlanoIaLimits._();

  static const premium = 120;
  static const enterprise = 400;

  static int forPlan(String? apiName) {
    final p = apiName?.trim().toUpperCase();
    if (p == 'ENTERPRISE') return enterprise;
    if (p == 'PREMIUM' || p == 'PRO') return premium;
    return 0;
  }
}
