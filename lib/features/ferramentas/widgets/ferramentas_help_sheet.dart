import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

/// Ajuda da tela Ferramentas.
Future<void> showFerramentasHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Ferramentas',
    subtitle: 'Tudo o que o seu plano oferece, agrupado por tarefa.',
    tips: const [
      FxHelpTip(
        'Buscar',
        'Digite o nome da ferramenta. Nomes antigos também funcionam.',
        icon: 'search',
      ),
      FxHelpTip(
        'Plano',
        'O selo "Pro" ou "Enterprise" mostra em qual plano a ferramenta entra. Tocar abre o upgrade.',
        icon: 'star',
      ),
      FxHelpTip(
        'Descrição',
        'A linha abaixo do nome diz para que serve a ferramenta.',
        icon: 'help',
      ),
    ],
  );
}
