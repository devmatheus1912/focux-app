/// PT-BR copy helpers for progressão de carga flows.
const progressaoObjetivoMax = 500;
const progressaoHistoricoMax = 8000;

String progressaoHubSubtitle(String alunoNome) {
  final nome = alunoNome.trim();
  if (nome.isEmpty) return 'Sugestão de carga, só se você pedir';
  return '$nome · só se você pedir';
}

String progressaoStickyLabel({required bool hasResult}) =>
    hasResult ? 'Gerar outra' : 'Gerar progressão';

String progressaoStickyLoadingLabel() => 'Gerando…';

String progressaoConfirmTitle() => 'Gerar progressão com IA?';

String progressaoConfirmMessage() =>
    'A IA sugere cargas. Nada entra no treino sem você aceitar.';

String progressaoConfirmLabel() => 'Gerar';

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
