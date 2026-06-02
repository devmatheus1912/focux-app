import '../data/dashboard_tool_shortcuts.dart';

class DashboardToolGroupSection {
  const DashboardToolGroupSection({
    required this.title,
    required this.shortcuts,
  });

  final String title;
  final List<DashboardToolShortcut> shortcuts;
}

/// Agrupa atalhos para escaneabilidade (Gestalt / densidade).
List<DashboardToolGroupSection> groupDashboardToolShortcuts(
  List<DashboardToolShortcut> shortcuts,
) {
  final operacao = <DashboardToolShortcut>[];
  final receita = <DashboardToolShortcut>[];
  final growth = <DashboardToolShortcut>[];
  final sistema = <DashboardToolShortcut>[];

  for (final shortcut in shortcuts) {
    final key = _groupKey(shortcut);
    switch (key) {
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
  final label = shortcut.label;
  if (shortcut.capability == 'financeiro' ||
      {
        'Dunning',
        'NDR / MRR',
        'Recorrência',
        'Loja',
        'Ofertas',
      }.contains(label)) {
    return _ToolGroupKey.receita;
  }
  if ({
    'Leads',
    'Lead Público',
    'Landing',
    'Indique',
    'Win-back',
    'NPS',
  }.contains(label)) {
    return _ToolGroupKey.growth;
  }
  if ({
    'Automações',
    'Broadcasts',
    'Setup D0',
    'Qualidade',
    'Equipe',
    'Grupo',
  }.contains(label)) {
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
