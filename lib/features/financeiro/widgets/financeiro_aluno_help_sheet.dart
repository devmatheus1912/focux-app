import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_icons.dart';

Future<void> showFinanceiroAlunoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar suas mensalidades',
    subtitle: 'O que está aberto e como falar com o personal.',
    tips: const [
      FxHelpTip(
        'Situação',
        'Aberto e atrasado somam o que ainda não foi pago. Pago some da urgência.',
        icon: FxIcons.dinheiro,
      ),
      FxHelpTip(
        'Ação',
        'Em cobrança aberta, gere o PIX na ficha. O status atualiza quando o pagamento confirmar. Chat fica para dúvida.',
        icon: FxIcons.pix,
      ),
      FxHelpTip(
        'Assinatura',
        'O chip abre a cobrança automática, se o personal criou.',
        icon: FxIcons.ia,
      ),
    ],
  );
}
