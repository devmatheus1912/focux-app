import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showAddExercicioHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como adicionar exercícios',
    subtitle:
        'Busque pelo nome ou explore por categoria. A prescrição ativa vale para os próximos que você incluir.',
    tips: const [
      FxHelpTip(
        'Buscar',
        'Digite 2+ letras, use favoritos ou filtre por vídeo. Toque no resultado para prescrever.',
        icon: 'search',
      ),
      FxHelpTip(
        'Explorar',
        'Modelos prontos, biblioteca completa ou categorias por movimento e grupo muscular.',
        icon: 'route',
      ),
      FxHelpTip(
        'Prescrição',
        'Séries, reps e descanso ficam na faixa inferior. Edite antes de adicionar ao treino.',
        icon: 'dumbbell',
      ),
      FxHelpTip(
        'Vídeo',
        'Envie sua demonstração ao selecionar um exercício — o aluno vê a mesma gravação.',
        icon: 'spark',
      ),
    ],
    footer: 'Dica: segure o card no treino para reordenar depois de adicionar.',
  );
}
