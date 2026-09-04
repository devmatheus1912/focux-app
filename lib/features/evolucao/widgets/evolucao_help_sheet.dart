import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showEvolucaoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar a evolução',
    subtitle: 'Medidas e recordes do aluno, no mesmo lugar.',
    tips: const [
      FxHelpTip(
        'Registrar',
        'O botão de baixo grava peso e circunferências, ou um recorde, conforme a visão.',
        icon: 'plus',
      ),
      FxHelpTip(
        'Visão',
        'Troque entre medidas e recordes no ícone de tendência no topo.',
        icon: 'trend',
      ),
    ],
  );
}
