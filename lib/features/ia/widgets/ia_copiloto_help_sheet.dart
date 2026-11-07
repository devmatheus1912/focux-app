import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../utils/ia_copiloto_display.dart';
import '../../../core/theme/fx_icons.dart';

Future<void> showIaCopilotoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar o Copiloto',
    subtitle: 'Sugestão da IA. Nada entra no aluno sem você revisar.',
    tips: const [
      FxHelpTip('Como calculamos', iaCopilotoComoCalculamos),
      FxHelpTip(
        'Aluno',
        'Escolha quem entra na análise. Sem aluno, o Copiloto não gera.',
        icon: FxIcons.grupo,
      ),
      FxHelpTip(
        'Modo',
        'Treino ou Progresso mudam o recorte. A IA não troca sozinha.',
        icon: FxIcons.ia,
      ),
      FxHelpTip(
        'Gerar',
        'Toque para pedir recomendações. Elas ficam na tela para você aceitar ou recusar.',
        icon: FxIcons.ia,
      ),
      FxHelpTip(
        'Tarefa',
        'Criar tarefa manda o recorte para o Command Center. Não aplica treino sozinho.',
        icon: FxIcons.artigo,
      ),
    ],
  );
}
