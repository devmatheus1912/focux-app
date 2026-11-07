import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../l10n/pt.dart';
import '../../../core/theme/fx_icons.dart';

Future<void> showEngajamentoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: ptS.engajamentoComoLerAAderencia,
    subtitle: ptS.engajamentoSeOAlunoEstaFirme,
    tips: [
      FxHelpTip(
        ptS.engajamentoAderencia2,
        ptS.engajamentoOMesmoNumeroDoPerfil,
        icon: FxIcons.calendario,
      ),
      FxHelpTip(
        ptS.engajamentoAtividade,
        ptS.engajamentoFiltrePorTreinosMedidasOu,
        icon: FxIcons.grafico,
      ),
    ],
  );
}
