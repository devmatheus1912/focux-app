import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showFinanceiroAlunoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar suas mensalidades',
    subtitle: 'O que está aberto e como falar com o personal.',
    tips: const [
      FxHelpTip(
        'Situação',
        'Aberto e atrasado somam o que ainda não foi pago. Pago some da urgência.',
        icon: 'coin',
      ),
      FxHelpTip(
        'Ação',
        'O botão de baixo abre o chat. PIX e baixa de pagamento o personal faz.',
        icon: 'message-circle',
      ),
    ],
  );
}
