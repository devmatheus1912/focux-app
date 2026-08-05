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
    _ => shortcut.displayFeatureName,
  };
}

/// Rótulo de seção colapsável (TalkBack / VoiceOver).
String dashboardCollapsibleSemanticsLabel(
  String title,
  bool expanded, {
  String? collapsedHint,
  String? collapsedActionLabel,
}) {
  if (expanded) {
    return '$title, expandido. Toque para recolher';
  }
  if (collapsedActionLabel != null && collapsedActionLabel.trim().isNotEmpty) {
    final hint =
        collapsedHint != null && collapsedHint.trim().isNotEmpty
            ? collapsedHint
            : 'Toque em $collapsedActionLabel para agir ou no ícone para expandir';
    return '$title, recolhido. $hint';
  }
  if (collapsedHint != null && collapsedHint.trim().isNotEmpty) {
    return '$title, recolhido. $collapsedHint';
  }
  return '$title, recolhido. Toque para expandir';
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

String dashboardAttentionCarouselSemantics(int total) {
  if (total <= 0) {
    return 'Nenhum item precisa de atenção';
  }
  return 'Carrossel horizontal, $total '
      '${total == 1 ? 'item' : 'itens'}. Deslize para ver mais';
}

String dashboardToolGroupSemanticsLabel(
  String title,
  bool expanded,
  int count,
) {
  return '${dashboardCollapsibleSemanticsLabel(title, expanded)}. '
      '$count ferramentas';
}
