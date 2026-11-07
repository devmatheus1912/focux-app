import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_icons.dart';

Future<void> showAddExercicioHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como adicionar exercícios',
    subtitle:
        'A biblioteca é a tela. Busque ou filtre, toque para incluir e siga para o próximo.',
    tips: const [
      FxHelpTip(
        'Buscar',
        'Digite o nome ou filtre por vídeo. Toque no exercício para adicionar na hora.',
        icon: FxIcons.buscar,
      ),
      FxHelpTip(
        'Favoritos',
        'Toque na estrela do card (ou segure a linha) para favoritar. O filtro Favoritos lista só esses.',
        icon: FxIcons.ia,
      ),
      FxHelpTip(
        'Categorias',
        'Todos lista A–Z. Músculo abre peito, costas, pernas… — busque pelo nome quando souber o exercício.',
        icon: FxIcons.rota,
      ),
      FxHelpTip(
        'Prescrição',
        'Séries, reps e descanso ficam na faixa Prescrição padrão, abaixo do título. Vale para os próximos que você incluir.',
        icon: FxIcons.treino,
      ),
      FxHelpTip(
        'Modelos',
        'No detalhe do treino, Sugerir exercícios traz os blocos da letra desta sessão (ex.: B · Costas e bíceps).',
        icon: FxIcons.ia,
      ),
    ],
    footer: 'Dica: segure o card no treino para reordenar depois de adicionar.',
  );
}
