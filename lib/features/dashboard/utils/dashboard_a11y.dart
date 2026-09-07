import '../data/dashboard_tool_shortcuts.dart';

/// Rótulos de leitor de tela em PT-BR (evita termos EN soltos no TalkBack).
String dashboardShortcutSemanticsLabel(DashboardToolShortcut shortcut) {
  return switch (shortcut.label) {
    'Cobrança auto' => 'Cobrança automática',
    'Recuperação' => 'Automação de recuperação de alunos',
    'Receita recorrente' => 'Relatório de receita recorrente NDR e MRR',
    'Pesquisa NPS' => 'Pesquisa de satisfação NPS',
    'Configuração inicial' => 'Assistente de configuração inicial',
    'Preços' || 'Preços inteligentes' => 'Financeiro e precificação',
    'Marca própria' => 'Identidade visual e logo personalizados',
    'Lead Público' || 'Captura pública' => 'Captura de leads públicos',
    'Captação' => 'Hub de captação de leads e landing',
    'Vendas' => 'Hub de pacotes e loja',
    'Financeiro' => 'Hub financeiro de receita, recorrência e cobrança',
    _ => shortcut.displayFeatureName,
  };
}

String dashboardAttentionItemSemantics({
  required int index,
  required int total,
  required String nome,
  required String titulo,
  required String subt,
  required String acao,
}) {
  return '$index de $total. $nome, $titulo. $subt. Toque para $acao';
}
