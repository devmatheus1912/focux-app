import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showRecorrenciaAlunoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar sua assinatura',
    subtitle: 'Cobrança mensal via Mercado Pago, se o personal criou.',
    tips: const [
      FxHelpTip(
        'Status',
        'Pendente espera você autorizar. Ativa cobra sozinha. Pausada não cobra até retomar.',
        icon: 'coin',
      ),
      FxHelpTip(
        'Autorizar',
        'Pendente abre o Mercado Pago. Ativa pode pausar. Pausada pode retomar. Sem assinatura, o botão chama o personal no chat.',
        icon: 'spark',
      ),
    ],
  );
}
