import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_icons.dart';

Future<void> showExercicioDetailHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar este exercício',
    subtitle: 'Oriente, veja o vídeo e edite o cadastro.',
    tips: const [
      FxHelpTip(
        'Vídeo',
        'Se houver demo ou vídeo seu, o player aparece acima. Sem vídeo, o atalho some.',
        icon: FxIcons.ia,
      ),
      FxHelpTip(
        'Editar',
        'O botão de baixo abre o cadastro. Favoritar fica no topo.',
        icon: FxIcons.estrela,
      ),
    ],
  );
}
