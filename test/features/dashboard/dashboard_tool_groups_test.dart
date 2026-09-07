import '../ferramentas/catalogo_fixture.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_tool_groups.dart';
import 'package:focux_app/features/ferramentas/data/ferramentas_catalogo_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groupCatalogoHubs lista hubs e não flat ~20', () {
    final catalogo = FerramentasCatalogo.fromJson(catalogoFixtureJson());
    final groups = groupCatalogoHubs(catalogo);
    expect(groups.length, lessThanOrEqualTo(8));
    expect(groups.map((g) => g.title), containsAll(['Operação', 'Captação', 'Vendas']));
    final leafCount = groups.fold<int>(0, (n, g) => n + g.shortcuts.length);
    expect(leafCount, lessThan(20));
  });

  test('filterDashboardToolShortcuts usa legacyIds', () {
    final catalogo = FerramentasCatalogo.fromJson(catalogoFixtureJson());
    final all = [
      for (final g in groupCatalogoHubs(catalogo)) ...g.shortcuts,
    ];
    final filtered = filterDashboardToolShortcuts(all, 'lead-publico');
    expect(filtered, isNotEmpty);
  });
}
