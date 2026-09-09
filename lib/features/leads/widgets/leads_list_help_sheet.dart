import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showLeadsListHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar o funil',
    subtitle: 'Encontre o lead, filtre o estágio e abra o detalhe.',
    tips: const [
      FxHelpTip(
        'Busca',
        'Nome, objetivo ou origem. A lista pagina no servidor.',
        icon: 'search',
      ),
      FxHelpTip(
        'Filtros',
        'Toque num estágio para recortar. Toque de novo para ver todos.',
        icon: 'users',
      ),
      FxHelpTip(
        'Novo lead',
        'O botão de baixo cadastra. O Kanban no topo mostra o mesmo funil em colunas.',
        icon: 'spark',
      ),
    ],
  );
}
