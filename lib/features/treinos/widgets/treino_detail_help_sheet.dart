import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showTreinoDetailHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como montar este treino',
    subtitle:
        'Inclua exercícios, ajuste a prescrição e atribua quando o plano estiver pronto.',
    tips: const [
      FxHelpTip(
        'De onde vem',
        'A faixa no topo diz se esta sessão é da ficha de um aluno ou de um modelo. Mudar uma sessão da ficha não muda o modelo de onde ela veio.',
        icon: 'calendar',
      ),
      FxHelpTip(
        'Adicionar',
        'O botão principal inclui da biblioteca. O menu do topo também chega lá.',
        icon: 'plus',
      ),
      FxHelpTip(
        'Prescrição',
        'Toque no exercício para séries, reps, carga e o vídeo de execução.',
        icon: 'dumbbell',
      ),
      FxHelpTip(
        'Vídeo',
        'O aluno vê a mesma gravação. O ? ao lado de Como filmar mostra as specs.',
        icon: 'spark',
      ),
      FxHelpTip(
        'Reordenar',
        'Segure o card e arraste. A ordem é salva neste treino.',
        icon: 'route',
      ),
      FxHelpTip(
        'Ações',
        'O menu do exercício duplica, substitui ou remove. O do treino atribui ou exclui.',
        icon: 'article',
      ),
    ],
  );
}
