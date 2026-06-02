import '../data/dashboard_tool_shortcuts.dart';

/// Rótulos de leitor de tela em PT-BR (evita termos EN soltos no TalkBack).
String dashboardShortcutSemanticsLabel(DashboardToolShortcut shortcut) {
  return switch (shortcut.label) {
    'Cobrança auto' => 'Cobrança automática',
    'Recuperação' => 'Automação de recuperação de alunos',
    'Receita recorrente' => 'Relatório de receita recorrente NDR e MRR',
    'Pesquisa NPS' => 'Pesquisa de satisfação NPS',
    'Configuração inicial' => 'Assistente de configuração inicial',
    'Retorno rápido' => 'Atalhos de retorno sobre investimento',
    'Preços inteligentes' => 'Financeiro e precificação',
    'Marca própria' => 'Identidade visual e logo personalizados',
    'Captura pública' => 'Captura de leads públicos',
    _ => shortcut.displayFeatureName,
  };
}

/// Rótulo de seção colapsável (TalkBack / VoiceOver).
String dashboardCollapsibleSemanticsLabel(String title, bool expanded) {
  return expanded
      ? '$title, expandido, toque para recolher'
      : '$title, recolhido, toque para expandir';
}

String dashboardToolGroupSemanticsLabel(
  String title,
  bool expanded,
  int count,
) {
  return '${dashboardCollapsibleSemanticsLabel(title, expanded)}. '
      '$count ferramentas';
}
