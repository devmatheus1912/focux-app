import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

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
        icon: 'phone',
      ),
      FxHelpTip(
        'Códigos de recuperação',
        'Aparecem só uma vez no setup. Guarde offline — servem se perder o celular.',
        icon: 'key',
      ),
      FxHelpTip(
        'Login',
        'Depois de ativo, cada entrada pede o código de 6 dígitos (ou um recovery).',
        icon: 'lock',
      ),
      FxHelpTip(
        'Desativar',
        'Precisa do autenticador + senha, ou autenticador + código por e-mail (contas Apple sem senha).',
        icon: 'settings',
      ),
      FxHelpTip(
        'E-mail oculto (Apple)',
        'Se o e-mail for @privaterelay.appleid.com, o código chega no Mail da conta Apple — não no Gmail.',
        icon: 'mail',
      ),
    ],
    footer: 'Em dúvida, ative só quando tiver o autenticador à mão.',
  );
}
