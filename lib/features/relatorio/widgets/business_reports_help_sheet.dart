import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showBusinessReportsHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como ler a receita recorrente',
    subtitle: 'MRR e retenção da base. Cobrança auto continua em Dunning.',
    tips: const [
      FxHelpTip(
        'MRR',
        'O que entrou neste mês, o previsto e o mês passado. Ticket é MRR dividido pelos ativos.',
        icon: 'coin',
      ),
      FxHelpTip(
        'NDR',
        'Acima de 100% a base cresce em reais. Abaixo, ou saiu aluno ou caiu o ticket.',
        icon: 'trend',
      ),
      FxHelpTip(
        'Cobrança',
        'A recuperação é a mesma do Dunning. Toque para abrir as falhas em aberto.',
        icon: 'alert-triangle',
      ),
    ],
  );
}
