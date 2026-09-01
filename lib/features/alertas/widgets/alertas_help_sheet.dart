import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showAlertasHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar os alertas',
    subtitle: 'Quem está esfriando. O check-in live continua no aluno.',
    tips: const [
      FxHelpTip(
        'Lista',
        'Alto e médio. Toque no aluno para ver o detalhe. Segure para escrever ou resolver.',
        icon: 'alert-triangle',
      ),
      FxHelpTip(
        'Limiares',
        'Dispara se ficou sem treino além do prazo ou se a aderência caiu. Ajuste em Quando dispara.',
        icon: 'target',
      ),
      FxHelpTip(
        'Resolver',
        'Tira o aluno desta caixa. Não apaga o histórico nem o 360.',
        icon: 'circle-check',
      ),
    ],
  );
}
