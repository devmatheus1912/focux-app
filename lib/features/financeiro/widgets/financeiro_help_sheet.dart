import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showFinanceiroHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar o financeiro',
    subtitle: 'Resumo do mês, lista de mensalidades e o recorte de cada aluno.',
    tips: const [
      FxHelpTip(
        'Resumo',
        'Recebido, pendente e meta. Toque em qualquer número para ir a Mensalidades.',
        icon: 'dollar-sign',
      ),
      FxHelpTip(
        'Vencimentos',
        'Toque no aluno para abrir só as mensalidades dele.',
        icon: 'calendar',
      ),
      FxHelpTip(
        'Mensalidades',
        'Lançar, marcar paga, PIX e cobrar no chat ficam na lista. Toque na linha para as ações.',
        icon: 'coin',
      ),
      FxHelpTip(
        'Métricas',
        'Troque o mês no seletor. Os números também abrem Mensalidades.',
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
