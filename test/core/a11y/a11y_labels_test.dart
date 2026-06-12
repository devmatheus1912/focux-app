import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_a11y.dart';
import 'package:focux_app/features/dashboard/data/dashboard_tool_shortcuts.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_a11y.dart';

void main() {
  test('dashboard shortcut labels are PT-BR', () {
    const shortcut = DashboardToolShortcut(
      icon: 'payments',
      label: 'Cobrança auto',
      featureName: 'financeiro',
    );
    expect(
      dashboardShortcutSemanticsLabel(shortcut),
      'Cobrança automática',
    );
  });

  test('dashboard collapsible semantics reflects expanded state', () {
    expect(
      dashboardCollapsibleSemanticsLabel('Ferramentas', true),
      contains('expandido'),
    );
    expect(
      dashboardCollapsibleSemanticsLabel('Ferramentas', false),
      contains('recolhido'),
    );
  });

  test('aluno360 module tile semantics includes badge', () {
    expect(
      aluno360ModuleTileSemantics(
        label: 'Treinos',
        sub: 'Ver ficha completa',
        badge: 'Novo',
      ),
      'Treinos, Novo. Ver ficha completa',
    );
  });

  test('aluno360 follow-up semantics reflects expand state', () {
    expect(
      aluno360FollowUpSemantics(subtitle: 'Ligar hoje', expanded: false),
      contains('Expandir'),
    );
  });
}
