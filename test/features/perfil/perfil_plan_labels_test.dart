import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/utils/perfil_plan_labels.dart';

void main() {
  test('ENTERPRISE_PRO shows PRO pill not FREE', () {
    expect(perfilPlanPillLabel('ENTERPRISE_PRO'), 'PRO');
    expect(perfilPlanSectionLabel('ENTERPRISE_PRO'), 'ENTERPRISE PRO');
  });

  test('unknown plan falls back to FREE pill', () {
    expect(perfilPlanPillLabel(''), 'FREE');
  });
}
