import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_icons.dart';

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
        icon: FxIcons.ia,
      ),
      FxHelpTip(
        'Dados pessoais',
        'Nome completo e WhatsApp entram no convite e no contato com alunos.',
        icon: FxIcons.grupo,
      ),
      FxHelpTip(
        'Profissional',
        'Comece pela especialidade. CREF e Instagram reforçam confiança na landing.',
        icon: FxIcons.estrela,
      ),
      FxHelpTip(
        'Bio',
        'Texto curto da metodologia. Até 500 caracteres — foque no diferencial.',
        icon: FxIcons.artigo,
      ),
    ],
  );
}
