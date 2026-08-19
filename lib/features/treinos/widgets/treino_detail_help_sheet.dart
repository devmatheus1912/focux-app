import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showTreinoDetailHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como montar este treino',
    subtitle:
        'Adicione, ajuste a prescrição e atribua quando o plano estiver pronto.',
    tips: const [
      FxHelpTip(
        'Adicionar',
        'O botão principal inclui da biblioteca. O menu do topo também chega lá.',
      ),
      FxHelpTip(
        'Prescrição',
        'Toque no exercício para séries, reps, carga e o vídeo de execução.',
      ),
      FxHelpTip(
        'Vídeo',
        'O aluno vê a mesma gravação. Toque no ? ao lado de Como filmar para as specs.',
      ),
      FxHelpTip(
        'Reordenar',
        'Segure o card e arraste. A ordem é salva neste treino.',
      ),
      FxHelpTip(
        'Ações',
        'O menu do exercício duplica, substitui ou remove. O do treino atribui ou exclui.',
      ),
    ],
  );
}
