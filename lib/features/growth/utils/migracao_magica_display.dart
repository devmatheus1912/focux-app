String migracaoIniciarLabel() => 'Analisar texto';

String migracaoIniciarAnalisandoLabel() => 'Analisando texto...';

String migracaoIniciarConfirmTitle() => 'Analisar este texto?';

String migracaoIniciarConfirmMessage() =>
    'Estrutura os alunos localmente. Nada é salvo ainda.';

String migracaoSalvarLabel(int count) =>
    count == 1 ? 'Confirmar 1 aluno' : 'Confirmar e salvar $count';

String migracaoSalvandoLabel() => 'Salvando alunos...';

String migracaoSalvarConfirmTitle(int count) =>
    count == 1 ? 'Salvar 1 aluno?' : 'Salvar $count alunos?';

String migracaoSalvarConfirmMessage() =>
    'Cria as fichas agora. Depois você envia o acesso um a um.';

String migracaoPlanilhaLabel() => 'Planilha';

String migracaoPlanilhaLendoLabel() => 'Lendo...';

String migracaoColarLabel() => 'Colar texto';

String migracaoFotoLabel() => 'Foto ou print';

String migracaoFotoLendoLabel() => 'Lendo print (OCR)...';

String migracaoDiscardTitle() => 'Sair da migração?';

String migracaoDiscardMessage() =>
    'O texto fica neste aparelho. Você retoma de onde parou.';

String migracaoDiscardConfirmLabel() => 'Sair';

String migracaoDiscardCancelLabel() => 'Continuar migração';

enum MigracaoFonte { planilha, texto, foto }

enum MigracaoEtapa { captura, revisao, acesso }

String migracaoEtapaLabel(MigracaoEtapa etapa) => switch (etapa) {
  MigracaoEtapa.captura => 'Etapa 1 de 3',
  MigracaoEtapa.revisao => 'Etapa 2 de 3',
  MigracaoEtapa.acesso => 'Etapa 3 de 3',
};

int migracaoEtapaIndex(MigracaoEtapa etapa) => switch (etapa) {
  MigracaoEtapa.captura => 1,
  MigracaoEtapa.revisao => 2,
  MigracaoEtapa.acesso => 3,
};

String migracaoQuestionTitle(MigracaoEtapa etapa) => switch (etapa) {
  MigracaoEtapa.captura => 'Como você quer trazer os alunos?',
  MigracaoEtapa.revisao => 'Confirmar estes alunos?',
  MigracaoEtapa.acesso => 'Enviar acesso',
};

String migracaoQuestionCaption(MigracaoEtapa etapa) => switch (etapa) {
  MigracaoEtapa.captura =>
    'Uma fonte por vez. Você revisa antes de gravar fichas.',
  MigracaoEtapa.revisao =>
    'Toque para editar. Remova duplicados antes de salvar.',
  MigracaoEtapa.acesso =>
    'Copie ou mande no WhatsApp um aluno por vez. Eles trocam a senha no primeiro acesso.',
};

String migracaoFonteLabel(MigracaoFonte fonte) {
  return switch (fonte) {
    MigracaoFonte.planilha => migracaoPlanilhaLabel(),
    MigracaoFonte.texto => migracaoColarLabel(),
    MigracaoFonte.foto => migracaoFotoLabel(),
  };
}

String migracaoContinueCaptureLabel({
  required MigracaoFonte fonte,
  required bool loading,
}) {
  if (loading) {
    return switch (fonte) {
      MigracaoFonte.planilha => migracaoPlanilhaLendoLabel(),
      MigracaoFonte.texto => migracaoIniciarAnalisandoLabel(),
      MigracaoFonte.foto => migracaoFotoLendoLabel(),
    };
  }
  return switch (fonte) {
    MigracaoFonte.planilha => 'Escolher arquivo',
    MigracaoFonte.texto => migracaoIniciarLabel(),
    MigracaoFonte.foto => 'Escolher foto',
  };
}

String migracaoVoltarLabel() => 'Voltar';

String migracaoIrParaListaLabel() => 'Ir para lista';

String migracaoCopiarConviteLabel() => 'Copiar convite';

String migracaoWhatsAppLabel() => 'WhatsApp';
