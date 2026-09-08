import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showRelatorioAlunoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como ler este relatório',
    subtitle: 'Aderência deste aluno. O panorama da base fica em Relatórios.',
    tips: const [
      FxHelpTip(
        'Período',
        '7 dias a 6 meses, ou um mês do calendário. O versus usa o mesmo tamanho, logo antes.',
        icon: 'calendar',
      ),
      FxHelpTip(
        'Aderência',
        'Treinos concluídos sobre o total no recorte. Abaixo de 50% vale pedir o check-in.',
        icon: 'trend',
      ),
      FxHelpTip(
        'PDF',
        'Com treinos no recorte, o botão de baixo exporta o PDF. Sem dados, ele abre a evolução.',
        icon: 'article',
      ),
    ],
  );
}
