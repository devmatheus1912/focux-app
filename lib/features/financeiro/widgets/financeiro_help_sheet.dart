import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showFinanceiroHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar o financeiro',
    subtitle:
        'A lista de mensalidades é o centro. Panorama e por mês ficam em Mais.',
    tips: const [
      FxHelpTip(
        'Mensalidades',
        'Lance, marque paga, PIX e cobre no chat. Toque na linha para o detalhe.',
        icon: 'coin',
      ),
      FxHelpTip(
        'Panorama',
        'Recebido, pendente e meta do mês. Abra em Mais → Panorama.',
        icon: 'dollar-sign',
      ),
      FxHelpTip(
        'Por mês',
        'Troque o mês e veja o recorte. Abra em Mais → Por mês.',
        icon: 'target',
      ),
      FxHelpTip(
        'Como calculamos',
        'Recebido do mês = mensalidades PAGO daquele mês. Pendente = soma ainda em aberto. Ticket = total pago ÷ quantidade de pagas. Atrasados = status ATRASADO.',
        icon: 'help',
      ),
    ],
  );
}
