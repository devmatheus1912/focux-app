import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

Future<void> showLeadDetailHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como usar este lead',
    subtitle: 'Qualificar, registrar contato e converter quando fechar.',
    tips: const [
      FxHelpTip(
        'Situação',
        'Status e a data do próximo follow-up. Mude o status no ícone do topo.',
        icon: 'users',
      ),
      FxHelpTip(
        'Contato',
        'Ligar e WhatsApp usam o telefone salvo. Toda conversa vira interação.',
        icon: 'chat',
      ),
      FxHelpTip(
        'Converter',
        'O botão de baixo cria o aluno. Se o plano estiver no limite, o app pede upgrade.',
        icon: 'spark',
      ),
    ],
  );
}
