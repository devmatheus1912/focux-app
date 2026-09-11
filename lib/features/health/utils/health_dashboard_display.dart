const saudeComoCalculamos =
    'Prontidão junta sono, passos e FC média do wearable (0–100). Sem permissão, a tela pede para conectar.';

String saudeAtualizarLabel() => 'Atualizar agora';

String saudeDesconectarLabel() => 'Desconectar saúde';

String saudeDesconectarConfirmTitle() => 'Desconectar saúde?';

String saudeDesconectarConfirmMessage() =>
    'O app deixa de ler Apple Health e Google Fit neste aparelho.';

/// Sync com o servidor falhou; dados locais ainda podem aparecer.
String saudeSyncSoftError([Object? _]) =>
    'Não sincronizamos com o servidor. Mostrando dados deste aparelho.';

String saudeSyncSoftRetryLabel() => 'Tentar sync';

String saudeConectarCtaLabel() => 'Conectar';
