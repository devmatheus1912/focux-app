String wizardStickyLabel({required bool allDone}) =>
    allDone ? 'Concluir' : 'Continuar';

String wizardHelpTitle() => 'Primeiros passos';

String wizardHelpSubtitle() =>
    'Complete o checklist. Pode fechar e voltar depois.';

String wizardHelpPassosBody() =>
    'Cada linha abre a tela daquele passo. O progresso atualiza sozinho.';

String wizardHelpConcluirBody() =>
    'Concluir esconde o checklist da Home. O que você já cadastrou fica.';

String wizardConfirmTitle() => 'Concluir os primeiros passos?';

String wizardConfirmMessage() =>
    'O checklist some da Home. Você continua usando o app normalmente.';

String wizardConfirmLabel() => 'Concluir';
