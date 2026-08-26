import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showTreinosListHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Biblioteca de treinos',
    subtitle:
        'Monte o plano base, abra com um toque e atribua quando precisar.',
    tips: const [
      FxHelpTip(
        'Novo plano',
        'O + no topo cria o treino. A biblioteca lista o que já está pronto.',
        icon: 'plus',
      ),
      FxHelpTip(
        'Abrir e ações',
        'Toque no card para abrir. O menu do card atribui, copia ou remove.',
        icon: 'dumbbell',
      ),
      FxHelpTip(
        'Seleção',
        'Segure um card ou use o checklist. A busca some e as ações sobem para a barra de baixo.',
        icon: 'circle-check',
      ),
    ],
  );
}
