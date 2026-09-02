String resetSenhaAlterarLabel() => 'Alterar senha';

String resetSenhaAlterandoLabel() => 'Salvando…';

String resetSenhaValidarCodigoLabel() => 'Preciso validar o código primeiro';

String resetSenhaConfirmTitle() => 'Alterar esta senha?';

String resetSenhaConfirmMessage() =>
    'Encerra as sessões abertas. Depois é preciso entrar de novo.';

String resetSenhaSucesso() => 'Senha alterada. Entre novamente.';

String resetSenhaHelpTitle() => 'Nova senha';

String resetSenhaHelpSubtitle() =>
    'Depois do código, escolha a senha. Mínimo 8 caracteres.';

String resetSenhaHelpSenhaBody() =>
    'A força aparece enquanto você digita. Confirme igual.';

String resetSenhaHelpSessaoBody() =>
    'Sem o código validado o app não troca a senha.';

String resetSenhaSubtitle({required bool hasNonce}) =>
    hasNonce
        ? 'Código validado. Escolha uma nova senha segura.'
        : 'Valide o código enviado por e-mail antes de definir a senha.';

bool resetSenhaHasNonce(String? nonce) =>
    nonce != null && nonce.trim().isNotEmpty;
