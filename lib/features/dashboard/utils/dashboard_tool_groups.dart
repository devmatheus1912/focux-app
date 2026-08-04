import '../data/dashboard_tool_shortcuts.dart';

class DashboardToolGroupSection {
  const DashboardToolGroupSection({
    required this.title,
    required this.shortcuts,
  });

  final String title;
  final List<DashboardToolShortcut> shortcuts;
}

/// Agrupa atalhos por rota/capability (não por label frágil).
List<DashboardToolGroupSection> groupDashboardToolShortcuts(
  List<DashboardToolShortcut> shortcuts,
) {
  final operacao = <DashboardToolShortcut>[];
  final receita = <DashboardToolShortcut>[];
  final growth = <DashboardToolShortcut>[];
  final sistema = <DashboardToolShortcut>[];

  for (final shortcut in shortcuts) {
    switch (_groupKey(shortcut)) {
      case _ToolGroupKey.receita:
        receita.add(shortcut);
      case _ToolGroupKey.growth:
        growth.add(shortcut);
      case _ToolGroupKey.sistema:
        sistema.add(shortcut);
      case _ToolGroupKey.operacao:
        operacao.add(shortcut);
    }
  }

  return [
    if (operacao.isNotEmpty)
      DashboardToolGroupSection(title: 'Operação', shortcuts: operacao),
    if (receita.isNotEmpty)
      DashboardToolGroupSection(title: 'Receita', shortcuts: receita),
    if (growth.isNotEmpty)
      DashboardToolGroupSection(title: 'Crescimento', shortcuts: growth),
    if (sistema.isNotEmpty)
      DashboardToolGroupSection(title: 'Sistema', shortcuts: sistema),
  ];
}

enum _ToolGroupKey { operacao, receita, growth, sistema }

_ToolGroupKey _groupKey(DashboardToolShortcut shortcut) {
  final route = shortcut.route ?? '';
  final cap = shortcut.capability ?? '';

  // Growth antes de capability financeiro (Leads usa cap financeiro).
  if (route.contains('/leads') ||
      route.contains('/landing') ||
      route.contains('/referral') ||
      route.contains('/recuperacao') ||
      route.contains('/nps') ||
      route.contains('/captura') ||
      route.contains('/marca')) {
    return _ToolGroupKey.growth;
  }

  if (cap == 'financeiro' ||
      cap == 'lojaDigital' ||
      route.contains('/financeiro') ||
      route.contains('/loja') ||
      route.contains('/ofertas') ||
      route.contains('/pacotes') ||
      route.contains('/recorrencia') ||
      route.contains('/cobranca') ||
      route.contains('/receita')) {
    return _ToolGroupKey.receita;
  }

  if (cap == 'automacoes' ||
      cap == 'equipeRbac' ||
      route.contains('/automacoes') ||
      route.contains('/broadcast') ||
      route.contains('/equipe') ||
      route.contains('/grupo') ||
      route.contains('/setup') ||
      route.contains('/qualidade') ||
      route.contains('/configuracao')) {
    return _ToolGroupKey.sistema;
  }

  return _ToolGroupKey.operacao;
}

List<DashboardToolShortcut> filterDashboardToolShortcuts(
  List<DashboardToolShortcut> shortcuts,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return shortcuts;
  return shortcuts
      .where(
        (s) =>
            s.label.toLowerCase().contains(q) ||
            s.displayFeatureName.toLowerCase().contains(q),
      )
      .toList();
}
