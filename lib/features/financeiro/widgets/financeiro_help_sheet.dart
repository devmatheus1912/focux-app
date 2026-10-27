import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showFinanceiroHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar o financeiro',
    subtitle: 'Três lugares: mensalidades, recorrências e resultados.',
    tips: const [
      FxHelpTip(
        'Mensalidades',
        'Os três números do topo abrem a lista: recebido, a receber e atrasado. '
        'Toque na linha para cobrar ou marcar como paga. Segure para marcar várias.',
        icon: 'coin',
      ),
      FxHelpTip(
        'Atrasadas',
        'O Focux marca como atrasada a cobrança vencida, na hora de lançar e todo dia de manhã. '
        'Não precisa atualizar nada.',
        icon: 'alert-triangle',
      ),
      FxHelpTip(
        'Recorrências',
        'Criam a mensalidade sozinhas todo mês e geram o PIX do aluno.',
        icon: 'repeat',
      ),
      FxHelpTip(
        'Resultados',
        'Quanto entrou no mês, quanto falta e quem atrasa. '
        'Recebido conta pela data do pagamento; o lançado conta pelo mês da cobrança.',
        icon: 'trend',
      ),
    ],
  );
}
