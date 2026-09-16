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
  VoidCallback? onPagarPix,
}) {
  final aberta = item.status == 'PENDENTE' || item.status == 'ATRASADO';
  final podePix = aberta && onPagarPix != null;

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
      FxHelpTip(
        'Como pagar',
        podePix
            ? 'Gere o PIX aqui. Depois que o pagamento confirmar, o status atualiza sozinho.'
            : item.status == 'PAGO'
            ? 'Esta cobrança já está quitada.'
            : 'Fale com o personal se precisar de ajuda com o pagamento.',
        icon: 'pix',
      ),
    ],
    extra: [
      if (podePix)
        FxLiquidPrimaryButton(
          label: 'Pagar com PIX',
          onPressed: () {
            // Mantém a sheet de cobrança aberta; o PIX empilha por cima.
            onPagarPix();
          },
        ),
      if (podePix) const SizedBox(height: 8),
      if (podePix)
        FxLiquidSecondaryButton(
          label: 'Falar com o personal',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            onFalar();
          },
        )
      else
        FxLiquidPrimaryButton(
          label: 'Falar com o personal',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            onFalar();
          },
        ),
    ],
  );
}
