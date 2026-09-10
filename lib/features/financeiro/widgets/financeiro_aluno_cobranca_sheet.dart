import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../features/alunos/utils/satellite_screen_utils.dart';
import '../data/financeiro_repository.dart';
import '../utils/financeiro_hub_display.dart';

Future<void> showFinanceiroAlunoCobrancaSheet(
  BuildContext context, {
  required Mensalidade item,
  required VoidCallback onFalar,
}) {
  return showFxHelpSheet(
    context,
    title: financeiroMensalidadeMesPorExtenso(item.mesReferencia),
    subtitle: financeiroMensalidadeStatusLabel(item.status),
    tips: [
      FxHelpTip('Valor', item.valor.format(), icon: 'coin'),
      FxHelpTip(
        'Situação',
        financeiroMensalidadeStatusLabel(item.status),
        icon: item.status == 'ATRASADO' ? 'alert-triangle' : 'circle-check',
      ),
      const FxHelpTip(
        'Como pagar',
        'Peça o PIX ou confirmação ao personal pelo chat. Pagamento direto no app ainda não está liberado para aluno.',
        icon: 'message-circle',
      ),
    ],
    extra: [
      FxLiquidPrimaryButton(
        label: 'Falar com o personal',
        onPressed: () {
          Navigator.of(context).pop();
          onFalar();
        },
      ),
    ],
  );
}
