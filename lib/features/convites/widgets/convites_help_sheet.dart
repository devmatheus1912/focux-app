import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showConvitesHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como convidar',
    subtitle: 'Um link. Um uso. 24 horas.',
    tips: const [
      FxHelpTip(
        'Gerar',
        'Cria um link seguro. Se já existe um válido, ele aparece na hora — sem gerar outro.',
        icon: 'plus',
      ),
      FxHelpTip(
        'Compartilhar',
        'Copiar some do clipboard em 1 minuto. WhatsApp abre com o texto pronto.',
        icon: 'message-circle',
      ),
      FxHelpTip(
        'Cadastro',
        'O aluno entra pelo link, troca a senha no primeiro acesso. Não envie o token solto.',
        icon: 'users',
      ),
    ],
  );
}
