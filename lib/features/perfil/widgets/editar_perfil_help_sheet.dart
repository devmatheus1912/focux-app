import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

/// Ajuda contextual de Editar Perfil (pilar 80).
Future<void> showEditarPerfilHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Como editar o perfil',
    subtitle: 'Nome e telefone alimentam a marca. O resto é vitrine.',
    tips: const [
      FxHelpTip(
        'Foto',
        'Aparece no app e na página pública. Prefira rosto nítido e fundo limpo.',
        icon: 'spark',
      ),
      FxHelpTip(
        'Dados pessoais',
        'Nome completo e WhatsApp entram no convite e no contato com alunos.',
        icon: 'users',
      ),
      FxHelpTip(
        'Profissional',
        'CREF, especialidade e Instagram reforçam confiança na landing.',
        icon: 'star',
      ),
      FxHelpTip(
        'Bio',
        'Texto curto da metodologia. Até 500 caracteres — foque no diferencial.',
        icon: 'article',
      ),
    ],
  );
}
