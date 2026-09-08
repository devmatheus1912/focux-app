import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showTrilhasHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar as trilhas',
    subtitle: 'Atribuir meta, marcar progresso e concluir marcos.',
    tips: const [
      FxHelpTip(
        'Atribuir',
        'O botão de baixo cria a trilha com tipo de meta e as primeiras etapas.',
        icon: 'plus',
      ),
      FxHelpTip(
        'Progresso',
        'Toque no marco pendente para concluir. Se a trilha tem valor, atualize no card.',
        icon: 'target',
      ),
      FxHelpTip(
        'Encerrar',
        'Uma trilha errada pode ser excluída no card. Isso não apaga o aluno.',
        icon: 'x',
      ),
    ],
  );
}
