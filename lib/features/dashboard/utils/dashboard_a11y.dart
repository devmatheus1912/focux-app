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
    _ => shortcut.displayFeatureName,
  };
}

String dashboardToolGroupSemanticsHint(String title, int count) {
  return 'Grupo $title, $count ferramentas. Toque para expandir ou recolher';
}
