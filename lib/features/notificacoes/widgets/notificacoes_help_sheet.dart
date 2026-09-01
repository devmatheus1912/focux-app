import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showNotificacoesHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar as notificações',
    subtitle: 'O que pediu ação. O destino abre no toque.',
    tips: const [
      FxHelpTip(
        'Lista',
        'Hoje, ontem e anteriores. Toque abre o aluno, o treino ou o aviso.',
        icon: 'bell',
      ),
      FxHelpTip(
        'Não lidas',
        'Ficam em destaque. “Ler todas” zera o sino da Home sem apagar o histórico.',
        icon: 'circle-check',
      ),
      FxHelpTip(
        'Radar',
        'Sinais de aluno que precisam de você. Cada linha é um aluno — não é o live do treino.',
        icon: 'spark',
      ),
    ],
  );
}
