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
        'Pendente espera você autorizar. Ativa cobra sozinha no vencimento.',
        icon: 'coin',
      ),
      FxHelpTip(
        'Autorizar',
        'O botão abre o Mercado Pago. Sem assinatura, peça ao personal para criar.',
        icon: 'spark',
      ),
    ],
  );
}
