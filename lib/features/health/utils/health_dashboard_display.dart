const saudeComoCalculamos =
    'Prontidão é um índice de 0 a 100 (não é porcentagem) que junta sono, passos e FC média do wearable. Sem permissão, a tela pede para conectar.';

String saudeAtualizarLabel() => 'Atualizar agora';

String saudeDesconectarLabel() => 'Desconectar saúde';

String saudeDesconectarConfirmTitle() => 'Desconectar saúde?';

String saudeDesconectarConfirmMessage() =>
    'O app deixa de ler Apple Health e Google Fit neste aparelho.';

/// Sync com o servidor falhou; dados locais ainda podem aparecer.
String saudeSyncSoftError([Object? _]) =>
    'Não sincronizamos com o servidor. Mostrando dados deste aparelho.';

String saudeConectarCtaLabel() => 'Conectar';
