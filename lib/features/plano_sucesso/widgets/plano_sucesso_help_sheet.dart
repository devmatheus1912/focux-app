import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showPlanoSucessoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar o plano de sucesso',
    subtitle: 'Objetivo, etapas e a próxima revisão.',
    tips: const [
      FxHelpTip(
        'Etapas',
        'O botão de baixo marca o próximo marco. Toque numa etapa pendente também vale.',
        icon: 'target',
      ),
      FxHelpTip(
        'Criar',
        'Sem plano, o mesmo botão pede o objetivo e as primeiras etapas.',
        icon: 'plus',
      ),
      FxHelpTip(
        'Revisão',
        'Com etapas em aberto, o ícone de calendário remarca o prazo. Plano completo usa o botão de baixo.',
        icon: 'calendar',
      ),
    ],
  );
}
