import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../utils/checkin_personal_display.dart';
import '../../../core/theme/fx_icons.dart';

Future<void> showCheckinPersonalHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar os check-ins',
    subtitle: 'Quem treinou. O live continua no app do aluno.',
    tips: [
      FxHelpTip('Como calculamos', checkinComoCalculamos),
      FxHelpTip(
        'Hoje',
        'Mesma conta do pulso da Home: só check-ins concluídos hoje.',
        icon: FxIcons.concluido,
      ),
      FxHelpTip(
        'Semana',
        'Os 6 dias anteriores. Toque no aluno para abrir o 360 — a lista não inicia treino.',
        icon: FxIcons.grupo,
      ),
      FxHelpTip(
        'Pendentes',
        'Alunos ativos com treino e sem check-in hoje. Cobrar treino manda um push para o aluno abrir a execução.',
        icon: FxIcons.notificacao,
      ),
      FxHelpTip(
        'Live',
        'Executar série e timer ficam no celular do aluno. Aqui o personal só acompanha.',
        icon: FxIcons.treino,
      ),
    ],
  );
}
