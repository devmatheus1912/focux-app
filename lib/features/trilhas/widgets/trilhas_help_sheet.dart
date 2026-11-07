import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_icons.dart';

Future<void> showTrilhasHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar as trilhas',
    subtitle: 'Atribuir meta, marcar progresso e concluir marcos.',
    tips: const [
      FxHelpTip(
        'Atribuir',
        'O botão de baixo cria a trilha com tipo de meta e as primeiras etapas.',
        icon: FxIcons.adicionar,
      ),
      FxHelpTip(
        'Progresso',
        'Toque no marco pendente para concluir. Nova etapa entra no card. Se a trilha tem valor, atualize ali.',
        icon: FxIcons.alvo,
      ),
      FxHelpTip(
        'Encerrar',
        'Uma trilha errada pode ser excluída no card. Isso não apaga o aluno.',
        icon: FxIcons.fechar,
      ),
    ],
  );
}

Future<void> showAlunoTrilhasHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Suas trilhas',
    subtitle: 'Metas que o personal atribuiu para você.',
    tips: const [
      FxHelpTip(
        'Progresso',
        'O percentual sobe quando o personal marca um marco ou atualiza a meta.',
        icon: FxIcons.grafico,
      ),
      FxHelpTip(
        'Treinos',
        'O botão de baixo abre seus treinos — é o caminho mais comum de avançar.',
        icon: FxIcons.treino,
      ),
    ],
  );
}
