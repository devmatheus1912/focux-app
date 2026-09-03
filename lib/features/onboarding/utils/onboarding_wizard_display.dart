String wizardStickyLabel({required bool allDone}) =>
    allDone ? 'Concluir' : 'Continuar';

String wizardFazerDepoisLabel() => 'Fazer depois';

String wizardDoneTitle() => 'Tudo pronto por aqui';

String wizardDoneBody() =>
    'Toque em Concluir para esconder o checklist da Home. O que você já cadastrou fica.';

int wizardEtapaCurrent({
  required int completedCount,
  required int totalCount,
  required bool allDone,
}) {
  if (totalCount <= 0) return 1;
  if (allDone) return totalCount;
  final current = completedCount + 1;
  if (current < 1) return 1;
  if (current > totalCount) return totalCount;
  return current;
}

String wizardEtapaLabel({
  required int completedCount,
  required int totalCount,
  required bool allDone,
}) {
  final total = totalCount <= 0 ? 1 : totalCount;
  return 'Etapa ${wizardEtapaCurrent(
    completedCount: completedCount,
    totalCount: total,
    allDone: allDone,
  )} de $total';
}

String wizardTitlesCaption({
  required String prefix,
  required List<String> titles,
}) {
  if (titles.isEmpty) return '';
  return '$prefix ${titles.join(', ')}';
}

String wizardHelpTitle() => 'Primeiros passos';

String wizardHelpSubtitle() =>
    'Uma etapa de cada vez. Pode fechar e voltar depois.';

String wizardHelpPassosBody() =>
    'Continuar abre o próximo passo. O progresso fica salvo; você retoma de onde parou.';

String wizardHelpConcluirBody() =>
    'Concluir esconde o checklist da Home. O que você já cadastrou fica.';

String wizardConfirmTitle() => 'Concluir os primeiros passos?';

String wizardConfirmMessage() =>
    'O checklist some da Home. Você continua usando o app normalmente.';

String wizardConfirmLabel() => 'Concluir';
