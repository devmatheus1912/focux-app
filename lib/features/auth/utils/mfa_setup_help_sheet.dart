import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_icons.dart';

/// Ajuda contextual da tela de MFA TOTP (Personal).
Future<void> showMfaSetupHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Autenticação em duas etapas',
    subtitle:
        'Um código no celular além da senha. Protege o acesso mesmo se a senha vazar.',
    tips: const [
      FxHelpTip(
        'App autenticador',
        'Use Google Authenticator, Authy, 1Password ou similar. Escaneie o QR (ou digite o secret).',
        icon: FxIcons.telefone,
      ),
      FxHelpTip(
        'Códigos de recuperação',
        'Aparecem só uma vez no setup. Guarde offline — servem se perder o celular.',
        icon: FxIcons.chave,
      ),
      FxHelpTip(
        'Login',
        'Depois de ativo, cada entrada pede o código de 6 dígitos (ou um recovery).',
        icon: FxIcons.cadeado,
      ),
      FxHelpTip(
        'Desativar',
        'Conta com senha: autenticador + senha (ou código por e-mail, se esqueceu). '
            'Conta que entra por Apple/Google: só o código do autenticador ou um de recuperação.',
        icon: FxIcons.ajustes,
      ),
    ],
    footer: 'Em dúvida, ative só quando tiver o autenticador à mão.',
  );
}
