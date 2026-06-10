/// PT-BR copy helpers for progressão de carga flows.
String progressaoPendingReviewLabel(int count) {
  if (count <= 0) return 'Revisar sugestões pendentes';
  if (count == 1) return 'Revisar 1 sugestão pendente';
  return 'Revisar $count sugestões pendentes';
}

String progressaoSavedForReviewSnack(int count) {
  if (count == 1) return '1 sugestão salva para revisão.';
  return '$count sugestões salvas para revisão.';
}

String progressaoAceitarSemanticsLabel(int count) =>
    count > 0
        ? 'Revisar $count sugestões pendentes de progressão'
        : 'Revisar sugestões pendentes de progressão';
