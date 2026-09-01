import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showRelatorioGlobalHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como ler os relatórios',
    subtitle: 'Panorama da base. O PDF de um aluno continua no 360.',
    tips: const [
      FxHelpTip(
        'Base',
        'A média é de todos os alunos, não só do ranking. O total também vem do servidor.',
        icon: 'trend',
      ),
      FxHelpTip(
        'Rankings',
        'Mais comprometidos e quem precisa de atenção. Toque no aluno para o relatório dele.',
        icon: 'users',
      ),
      FxHelpTip(
        'Atenção',
        'Quem está embaixo não é alerta. Para esfriamento, use Alertas.',
        icon: 'alert-triangle',
      ),
    ],
  );
}
