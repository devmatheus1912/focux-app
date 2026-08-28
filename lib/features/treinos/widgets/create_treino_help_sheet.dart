import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showCreateTreinoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Novo treino',
    subtitle: 'Monte o plano base agora. Os exercícios entram no próximo passo.',
    tips: const [
      FxHelpTip(
        'Modelos rápidos',
        'Toque em um modelo para pré-preencher nome e objetivo.',
        icon: 'dumbbell',
      ),
      FxHelpTip(
        'Plano base',
        'Nome é obrigatório. Nível e descrição ajudam na biblioteca e na atribuição.',
        icon: 'circle-check',
      ),
      FxHelpTip(
        'Próximo passo',
        'Depois de criar, você adiciona exercícios e séries na tela seguinte.',
        icon: 'plus',
      ),
    ],
  );
}
