import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_icons.dart';

Future<void> showRecorrenciaAlunoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar sua assinatura',
    subtitle: 'Mensalidade todo mês, paga por PIX direto ao seu personal.',
    tips: const [
      FxHelpTip(
        'Status',
        'Ativa lança a mensalidade 5 dias antes do vencimento. Pausada não lança até retomar.',
        icon: FxIcons.dinheiro,
      ),
      FxHelpTip(
        'Pagar',
        'Abra a mensalidade no Financeiro, pague o PIX e toque em avisar o personal. Sem assinatura, o botão chama o personal no chat.',
        icon: FxIcons.ia,
      ),
      FxHelpTip(
        'Financeiro',
        'O chip abre o extrato. Lá ficam cobranças avulsas e o histórico.',
        icon: FxIcons.dinheiro,
      ),
    ],
  );
}
