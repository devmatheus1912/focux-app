import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showFinanceiroHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar o financeiro',
    subtitle: 'Resumo do mês, mensalidades e o recorte de cada aluno.',
    tips: const [
      FxHelpTip(
        'Resumo',
        'Recebido, pendente e meta. Toque em qualquer número para ir à aba Mensalidades.',
        icon: 'dollar-sign',
      ),
      FxHelpTip(
        'Vencimentos',
        'Toque no aluno para abrir só as mensalidades dele. Sem id, cai na lista completa.',
        icon: 'clock',
      ),
      FxHelpTip(
        'Mensalidades',
        'Lançar, marcar paga, PIX e cobrar no chat ficam nesta aba — o Resumo só aponta o caminho.',
        icon: 'coin',
      ),
      FxHelpTip(
        'Métricas',
        'Troque o mês no topo. Os números também abrem Mensalidades.',
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
