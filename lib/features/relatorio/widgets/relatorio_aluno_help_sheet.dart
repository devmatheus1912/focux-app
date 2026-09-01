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
        '7 dias a 6 meses, ou um intervalo seu. O comparativo só aparece nos recortes prontos.',
        icon: 'calendar',
      ),
      FxHelpTip(
        'Aderência',
        'Treinos concluídos sobre o total no recorte. Abaixo de 50% vale pedir o check-in.',
        icon: 'trend',
      ),
      FxHelpTip(
        'PDF',
        'Exporta o recorte que está na tela. Não muda treino nem mensalidade.',
        icon: 'article',
      ),
    ],
  );
}
