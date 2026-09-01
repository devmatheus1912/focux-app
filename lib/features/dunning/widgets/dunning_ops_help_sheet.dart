import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showDunningOpsHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar a cobrança automática',
    subtitle: 'Falhas de pagamento da base. A taxa é a mesma da Receita recorrente.',
    tips: const [
      FxHelpTip(
        'Taxa',
        'Recuperadas dividido pelo total de falhas. Quanto maior, mais a cobrança auto está funcionando.',
        icon: 'trend',
      ),
      FxHelpTip(
        'Em aberto',
        'Cada linha é uma falha. Toque para marcar como recuperada quando o pagamento entrar.',
        icon: 'alert-triangle',
      ),
      FxHelpTip(
        'Assinatura Focux',
        'É a sua assinatura do app, não a mensalidade do aluno. Mensalidade aparece com o contexto certo.',
        icon: 'coin',
      ),
    ],
  );
}
