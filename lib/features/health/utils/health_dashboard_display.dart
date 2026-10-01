const saudeComoCalculamos =
    'Prontidão é um índice de 0 a 100 (não é porcentagem) que junta sono, passos e FC média do wearable. Sem sono nem batimentos, não calculamos: passos sozinhos não medem recuperação.';

String saudeAtualizarLabel() => 'Atualizar agora';

String saudeDesconectarLabel() => 'Desconectar saúde';

String saudeDesconectarConfirmTitle() => 'Desconectar saúde?';

String saudeDesconectarConfirmMessage() =>
    'O app deixa de ler Apple Health e Google Fit neste aparelho.';

/// Sync com o servidor falhou; dados locais ainda podem aparecer.
String saudeSyncSoftError([Object? _]) =>
    'Não sincronizamos com o servidor. Mostrando dados deste aparelho.';

String saudeConectarCtaLabel() => 'Conectar';

const saudeGerenciarConexaoLabel = 'Gerenciar conexão';

/// Sincronizou, mas sem sono nem FC o servidor não dá nota.
const saudeSemScoreMensagem =
    'Precisamos do seu sono ou batimentos para calcular a prontidão.';

const saudeSemScoreAcao = 'Como liberar';

const saudeSemDadosHoje = 'Sem dados hoje';
const saudeSemBatimento = 'Sem dados de batimento';
const saudeSemSono = 'Use o relógio para dormir';

/// Zero do wearable é ausência de leitura, não medida: mostra "--".
String saudeValorOuTraco(num valor, String Function(num v) formatar) =>
    valor > 0 ? formatar(valor) : '--';
