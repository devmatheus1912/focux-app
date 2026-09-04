import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showAlimentarHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar a nutrição',
    subtitle: 'Planos, macros e refeições do aluno.',
    tips: const [
      FxHelpTip(
        'Criar',
        'O botão de baixo abre um plano novo com meta de calorias e macros.',
        icon: 'plus',
      ),
      FxHelpTip(
        'Refeições',
        'Toque no plano para ver e editar as refeições prescritas.',
        icon: 'target',
      ),
    ],
  );
}
