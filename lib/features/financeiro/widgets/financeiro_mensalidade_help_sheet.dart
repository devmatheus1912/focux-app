import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showFinanceiroMensalidadeHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar esta mensalidade',
    subtitle: 'Valor, mês, vencimento e status desta cobrança.',
    tips: const [
      FxHelpTip(
        'Pagar',
        'Marcar como paga confirma o recebimento. PIX copia o código para cobrar agora.',
        icon: 'coin',
      ),
      FxHelpTip(
        'Cobrar',
        'Chat manda o lembrete ao aluno. Registrar contato só anota que você falou.',
        icon: 'message-circle',
      ),
      FxHelpTip(
        'Editar',
        'Ajuste valor ou vencimento sem marcar pago. O chip Financeiro volta à lista.',
        icon: 'dollar-sign',
      ),
    ],
  );
}
