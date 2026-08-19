import 'package:flutter/material.dart';

import '../../../core/theme/hero_teal.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'treino_home_sheet.dart';

Future<void> showTreinosListHelpSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: fxTransparent,
    barrierColor: heroScrim(0.34),
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return TreinoHelpSheetFrame(
        isDark: isDark,
        icon: Icons.help_outline_rounded,
        title: 'Biblioteca de treinos',
        subtitle:
            'Crie um plano base, abra com um toque e atribua quando precisar.',
        tips: const [
          (
            'Novo plano',
            'O + no topo cria o treino. A biblioteca lista o que já está pronto.',
          ),
          (
            'Ações',
            'Toque no card para abrir. O menu do card atribui, copia ou remove.',
          ),
          (
            'Seleção',
            'Segure um card ou use o checklist. A busca some e as ações sobem para a barra de baixo.',
          ),
        ],
      );
    },
  );
}
