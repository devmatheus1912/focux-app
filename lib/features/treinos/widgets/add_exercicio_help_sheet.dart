import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showAddExercicioHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como adicionar exercícios',
    subtitle:
        'A biblioteca é a tela. Busque ou filtre, toque para incluir e siga para o próximo.',
    tips: const [
      FxHelpTip(
        'Buscar',
        'Digite o nome, use favoritos ou filtre por vídeo. Toque no exercício para adicionar na hora.',
        icon: 'search',
      ),
      FxHelpTip(
        'Categorias',
        'Todos lista A–Z. Músculo abre peito, costas, pernas… — busque pelo nome quando souber o exercício.',
        icon: 'route',
      ),
      FxHelpTip(
        'Prescrição',
        'Séries, reps e descanso ficam na faixa Prescrição padrão, abaixo do título. Vale para os próximos que você incluir.',
        icon: 'dumbbell',
      ),
      FxHelpTip(
        'Modelos',
        'Para montar o treino inteiro de uma vez, use Montar por modelo no detalhe do treino.',
        icon: 'spark',
      ),
    ],
    footer: 'Dica: segure o card no treino para reordenar depois de adicionar.',
  );
}
