import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showFinanceiroMensalidadeHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar esta mensalidade',
    subtitle: 'Valor, mês, vencimento e estado desta cobrança.',
    tips: const [
      FxHelpTip(
        'Marcar como paga',
        'Confirme só quando o valor já entrou. Dá para desfazer pelo menu ⋮.',
        icon: 'coin',
      ),
      FxHelpTip(
        'Cobrar',
        'Escolha entre mandar a cobrança no chat ou gerar o PIX copia e cola. '
        'Registrar contato, só anota que você falou.',
        icon: 'message-circle',
      ),
      FxHelpTip(
        'Editar e cancelar',
        'No menu ⋮: ajuste valor ou vencimento, ou cancele a cobrança. '
        'Se o vencimento já passou, ela fica atrasada sozinha.',
        icon: 'dollar-sign',
      ),
    ],
  );
}
