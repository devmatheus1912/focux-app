import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_icons.dart';

Future<void> showLeadDetailHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar este lead',
    subtitle: 'Qualificar, registrar contato e converter quando fechar.',
    tips: const [
      FxHelpTip(
        'Situação',
        'Status e a data do próximo follow-up. Mude o status no ícone do topo.',
        icon: FxIcons.grupo,
      ),
      FxHelpTip(
        'Contato',
        'Ligar e WhatsApp usam o telefone salvo. Toda conversa vira interação.',
        icon: FxIcons.chat,
      ),
      FxHelpTip(
        'Converter',
        'O botão de baixo cria o aluno. Se o plano estiver no limite, o app pede upgrade.',
        icon: FxIcons.ia,
      ),
    ],
  );
}
