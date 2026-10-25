import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../utils/alunos_microcopy.dart';

/// Ajuda contextual da lista de alunos (pilar 80).
Future<void> showAlunosListHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: AlunosMicrocopy.helpA11y,
    subtitle: 'Veja quem são seus alunos, filtre por situação e abra a ficha com um toque.',
    tips: const [
      FxHelpTip(
        'Filtros',
        'Todos e Ativos ficam sempre. Contato hoje, Em atraso, Em risco, Convites e Inativos só aparecem quando há alguém. O filtro marcado é o que está valendo.',
        icon: 'search',
      ),
      FxHelpTip(
        'Contato hoje',
        'Quem está em risco, inadimplente ou parado há dias. Na Hoje, o "Agora" mostra os mais urgentes.',
        icon: 'bell',
      ),
      FxHelpTip(
        'Convite pendente',
        'Quem ainda não entrou mostra "Ainda não entrou" e o botão Reenviar.',
        icon: 'users',
      ),
      FxHelpTip(
        'Novo aluno e importar',
        '"Novo aluno" cadastra um. O botão ao lado importa vários de planilha, texto ou print.',
        icon: 'plus',
      ),
      FxHelpTip(
        'Lista compacta',
        'Em Organizar lista, reduz o card para caber mais gente.',
        icon: 'target',
      ),
      FxHelpTip(
        'Seleção',
        'Segure um card e use Ações na barra de baixo: pagar, pausar, bloquear, reativar ou excluir.',
        icon: 'circle-check',
      ),
    ],
  );
}
