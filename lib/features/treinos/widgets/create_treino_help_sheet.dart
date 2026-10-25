import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showCreateTreinoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Novo treino',
    subtitle: 'Só o nome basta. Os exercícios entram no passo seguinte.',
    tips: const [
      FxHelpTip(
        'Nome',
        'É o único campo obrigatório. Você pode partir de um modelo rápido para pré-preencher o nome.',
        icon: 'dumbbell',
      ),
      FxHelpTip(
        'Plano base',
        'Nível e descrição ajudam na biblioteca e na hora de atribuir.',
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
