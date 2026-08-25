import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/utils/perfil_plan_labels.dart';

void main() {
  test('ENTERPRISE_PRO alias cai no código ENTERPRISE', () {
    expect(perfilPlanPillLabel('ENTERPRISE_PRO'), 'ENTERPRISE');
  });

  test('PREMIUM alias cai no pill PRO', () {
    expect(perfilPlanPillLabel('PREMIUM'), 'PRO');
  });

  test('unknown plan falls back to FREE pill', () {
    expect(perfilPlanPillLabel(''), 'FREE');
  });

  test('linha de planos usa rótulo iOS, não o código da API', () {
    expect(perfilPlanRowValue('ENTERPRISE'), 'Enterprise');
    expect(perfilPlanRowValue('PREMIUM'), 'Pro');
    expect(perfilPlanRowValue(''), 'Grátis');
  });
}
