String migracaoIniciarLabel() => 'Analisar texto';

String migracaoIniciarAnalisandoLabel() => 'Analisando texto...';

String migracaoIniciarConfirmTitle() => 'Analisar este texto?';

String migracaoIniciarConfirmMessage() =>
    'Estrutura os alunos localmente. Nada é salvo ainda.';

String migracaoSalvarLabel(int count) =>
    'Confirmar e salvar $count alunos';

String migracaoSalvandoLabel() => 'Salvando alunos...';

String migracaoSalvarConfirmTitle(int count) => 'Salvar $count alunos?';

String migracaoSalvarConfirmMessage() =>
    'Cria as fichas agora. Duplicados são ignorados.';

String migracaoPlanilhaLabel() => 'Planilha';

String migracaoPlanilhaLendoLabel() => 'Lendo...';

String migracaoColarLabel() => 'Colar texto';

String migracaoFotoLabel() => 'Foto ou print';

String migracaoFotoLendoLabel() => 'Lendo print (OCR)...';

String migracaoDiscardTitle() => 'Sair da migração?';

String migracaoDiscardMessage() =>
    'Há texto ou alunos revisados que ainda não foram salvos.';

String migracaoDiscardConfirmLabel() => 'Sair sem salvar';

String migracaoDiscardCancelLabel() => 'Continuar migração';

enum MigracaoFonte { planilha, texto, foto }

String migracaoEtapaLabel({required bool reviewing}) =>
    reviewing ? 'Etapa 2 de 2' : 'Etapa 1 de 2';

String migracaoQuestionTitle({required bool reviewing}) =>
    reviewing
        ? 'Confirmar estes alunos?'
        : 'Como você quer trazer os alunos?';

String migracaoQuestionCaption({required bool reviewing}) =>
    reviewing
        ? 'Toque para editar. Remova duplicados antes de salvar.'
        : 'Uma fonte por vez. Você revisa antes de gravar fichas.';

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
