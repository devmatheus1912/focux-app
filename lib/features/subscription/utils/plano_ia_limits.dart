/// Cotas mensais de IA — espelham {@code PlanoLimites} no backend.
class PlanoIaLimits {
  PlanoIaLimits._();

  static const pro = 200;
  static const premium = pro;
  static const enterprise = 600;

  static int forPlan(String? apiName) {
    final p = apiName?.trim().toUpperCase();
    if (p == 'ENTERPRISE' || p == 'ENTERPRISE_PRO') return enterprise;
    if (p == 'PREMIUM' || p == 'PRO') return pro;
    return 0;
  }
}
