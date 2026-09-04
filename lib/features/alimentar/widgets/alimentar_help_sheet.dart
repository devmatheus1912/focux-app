import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showAlimentarHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar a nutrição',
    subtitle: 'Planos, macros e refeições do aluno.',
    tips: const [
      FxHelpTip(
        'Criar',
        'O botão de baixo abre um plano novo com meta de calorias e macros.',
        icon: 'plus',
      ),
      FxHelpTip(
        'Refeições',
        'Toque no plano para ver e editar as refeições prescritas.',
        icon: 'target',
      ),
    ],
  );
}

Future<void> showAlimentarPlanoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar este plano',
    subtitle: 'Refeições, macros e dieta com IA.',
    tips: const [
      FxHelpTip(
        'Nova refeição',
        'O botão de baixo adiciona horário, macros e alimentos neste plano. Toque numa refeição para editar.',
        icon: 'plus',
      ),
      FxHelpTip(
        'IA',
        'O ícone de spark gera a dieta. Você confirma os dados antes; nada entra sozinho.',
        icon: 'spark',
      ),
      FxHelpTip(
        'Remover',
        'A lixeira na refeição pede confirmação e some só daquele item.',
        icon: 'x',
      ),
    ],
  );
}
