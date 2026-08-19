import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

/// Ajuda contextual da lista de alunos (pilar 80).
Future<void> showAlunosListHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Lista de alunos',
    subtitle:
        'Priorize contato, filtre por status e abra a ficha com um toque.',
    tips: const [
      FxHelpTip(
        'Contato hoje',
        'Chip na lista. Banner só aparece quando parte da base precisa de contato — não quando todos precisam.',
      ),
      FxHelpTip(
        'Filtros e busca',
        'Use os chips para focar a base. A busca considera nome e objetivo.',
      ),
      FxHelpTip(
        'Lista compacta',
        'Em Organizar lista, ative compacta para ver mais alunos na tela.',
      ),
    ],
  );
}
