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
      group: DashboardToolGroup.receita,
    );
    expect(
      dashboardShortcutSemanticsLabel(shortcut),
      'Cobrança automática',
    );
  });

  test('dashboard attention item semantics includes rank', () {
    expect(
      dashboardAttentionItemSemantics(
        index: 1,
        total: 2,
        nome: 'Ana',
        titulo: 'Inadimplente',
        subt: 'R\$ 200 pendente',
        acao: 'Cobrar',
      ),
      '1 de 2. Ana, Inadimplente. R\$ 200 pendente. Toque para Cobrar',
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

  test('aluno360 follow-up semantics includes subtitle and expand hint', () {
    expect(
      aluno360FollowUpSemantics(subtitle: 'Ligar hoje', expanded: false),
      'Próximo contato. Ligar hoje. Toque para expandir ações',
    );
    expect(
      aluno360FollowUpSemantics(subtitle: 'Ligar hoje', expanded: true),
      'Próximo contato. Ligar hoje. Toque para recolher ações',
    );
  });
}
