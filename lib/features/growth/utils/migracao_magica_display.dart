import '../../../l10n/app_localizations.dart';

String migracaoIniciarLabel() => 'Analisar texto';

String migracaoIniciarAnalisandoLabel() => 'Analisando texto...';

String migracaoIniciarConfirmTitle() => 'Analisar este texto?';

String migracaoIniciarConfirmMessage() =>
    'Estrutura os alunos localmente. Nada é salvo ainda.';

String migracaoSalvarLabel(int count) => switch (count) {
  0 => 'Selecione alunos',
  1 => 'Importar 1 aluno',
  _ => 'Importar $count alunos',
};

String migracaoIgnoradasLabel(int count) =>
    count == 1 ? '1 linha ignorada' : '$count linhas ignoradas';

String migracaoCampoLabel(String campo) => switch (campo) {
  'nome' => 'Nome',
  'email' => 'E-mail',
  'telefone' => 'Telefone',
  _ => 'Objetivo',
};

String migracaoVazioTitle() => 'Não encontramos alunos aqui';

String migracaoVazioDica({bool deFoto = false}) => deFoto
    ? 'Pouco identificado nesse print. Tente tirar foto só da lista de alunos, '
        'sem menus ou outros elementos — ou cole o texto diretamente.'
    : 'Use uma planilha com colunas Nome, Telefone e E-mail. '
        'Ou envie o print da sua lista de contatos.';

String migracaoSalvandoLabel() => 'Salvando alunos...';

String migracaoSalvarConfirmTitle(int count) =>
    count == 1 ? 'Salvar 1 aluno?' : 'Salvar $count alunos?';

String migracaoSalvarConfirmMessage() =>
    'Quem tem e-mail recebe o convite sozinho. Quem só tem telefone fica para o WhatsApp.';

String migracaoWhatsappFolha() =>
    'Estes só têm telefone. O texto já está copiado.';

String migracaoWhatsappAbrirLabel() => 'Abrir WhatsApp';

String migracaoCopiarConvitesLabel(int count) =>
    count == 1 ? 'Copiar o convite' : 'Copiar os $count convites';

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

String migracaoQuestionCaption(MigracaoEtapa etapa, S s) => switch (etapa) {
  MigracaoEtapa.captura =>
    'Uma fonte por vez. Você revisa antes de gravar fichas.',
  MigracaoEtapa.revisao =>
    'Toque para editar. Desmarque quem não entra.',
  MigracaoEtapa.acesso => s.migracaoAcessoCaption,
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


/// Uma frase sobre a fonte escolhida: o texto de OCR só aparece na foto.
String migracaoAjudaDaFonte(MigracaoFonte fonte) => switch (fonte) {
  MigracaoFonte.planilha => 'A planilha vai direto para a revisão.',
  MigracaoFonte.texto => 'Cole os dados dos alunos. Você revisa antes de gravar.',
  MigracaoFonte.foto =>
    'A foto é lida no seu aparelho (leitura gratuita). Você revisa antes de gravar.',
};

final _temLetraOuNumero = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// Amostras de linhas ignoradas que dizem alguma coisa (não "|" nem vazias).
List<String> migracaoAmostrasReais(List<String> amostras) => [
  for (final linha in amostras)
    if (_temLetraOuNumero.hasMatch(linha)) linha,
];

/// Total de ignoradas sem as que são só símbolo, que o personal não precisa ver.
int migracaoIgnoradasReais(int total, List<String> amostras) {
  final descartadas = amostras.length - migracaoAmostrasReais(amostras).length;
  final real = total - descartadas;
  return real < 0 ? 0 : real;
}
