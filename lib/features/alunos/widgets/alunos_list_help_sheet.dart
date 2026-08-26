import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../utils/alunos_microcopy.dart';

/// Ajuda contextual da lista de alunos (pilar 80).
Future<void> showAlunosListHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: AlunosMicrocopy.helpA11y,
    subtitle:
        'Priorize contato, filtre por status e abra a ficha com um toque.',
    tips: const [
      FxHelpTip(
        'Contato hoje',
        'Chip na lista. O banner só aparece quando parte da base precisa — não quando todos precisam.',
        icon: 'bell',
      ),
      FxHelpTip(
        'Filtros e busca',
        'Chips Ativo, Inativo e Bloqueado. A busca cobre nome e objetivo.',
        icon: 'search',
      ),
      FxHelpTip(
        'Lista compacta',
        'Em Organizar lista, oculta o e-mail e reduz o card para caber mais gente.',
        icon: 'users',
      ),
      FxHelpTip(
        'Seleção',
        'Segure um card para ações em lote. Pagar e outras sobem na barra de baixo.',
        icon: 'circle-check',
      ),
    ],
  );
}
