import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/dashboard_tool_shortcuts.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_a11y.dart';
import 'package:focux_app/features/ferramentas/data/ferramentas_catalogo_models.dart';

void main() {
  test('dashboard shortcut labels are PT-BR', () {
    final shortcut = DashboardToolShortcut.fromEntrada(
      const CatalogoEntrada(
        id: 'cobranca-auto',
        titulo: 'Cobrança auto',
        featureGate: 'FINANCEIRO',
        legacyIds: ['cobranca-auto'],
      ),
    );
    expect(
      dashboardShortcutSemanticsLabel(shortcut),
      'Cobrança automática',
    );
  });


}
