import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showEngajamentoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como ler a aderência',
    subtitle: 'Se o aluno está firme e se precisa de você.',
    tips: const [
      FxHelpTip(
        'Aderência',
        'O mesmo número do perfil do aluno. O calendário mostra as últimas 5 semanas.',
        icon: 'calendar',
      ),
      FxHelpTip(
        'Atividade',
        'Filtre por treinos, medidas ou mensagens. Toque numa linha para abrir. Treinos cancelados não contam.',
        icon: 'trend',
      ),
    ],
  );
}
