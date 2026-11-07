import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_icons.dart';

/// Ajuda da ficha do aluno: a semana, o prazo, os modelos e as fichas anteriores.
Future<void> showFichaHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Ficha do aluno',
    subtitle: 'A semana de treinos que o aluno segue, com prazo de validade.',
    tips: const [
      FxHelpTip(
        'Montar a semana',
        'Toque num dia para adicionar um treino. O "…" da sessão marca descanso, move, copia ou põe um segundo treino no dia.',
        icon: FxIcons.calendario,
      ),
      FxHelpTip(
        'Vale por',
        'Escolha por quantas semanas a ficha vale. O Focux avisa 7 dias antes e no dia do vencimento, e você renova pelo próprio aviso.',
        icon: FxIcons.notificacao,
      ),
      FxHelpTip(
        'Modelos',
        'Aplique um modelo, salve esta ficha como modelo ou use em outro aluno. A ficha atual sai e entra uma cópia; editar uma não muda a outra.',
        icon: FxIcons.artigo,
      ),
      FxHelpTip(
        'Fichas anteriores',
        'Quando você troca a ficha inteira, a anterior fica guardada. Dá para consultar e usar como base de novo.',
        icon: FxIcons.rota,
      ),
      FxHelpTip(
        'Volume da semana',
        'Mostra as séries de trabalho por grupo muscular, só como referência. Nada bloqueia a sua prescrição.',
        icon: FxIcons.grafico,
      ),
      FxHelpTip(
        'Recomeçar',
        'Limpa a semana. Os treinos continuam salvos e a ficha de agora vai para as anteriores.',
        icon: FxIcons.atualizar,
      ),
    ],
  );
}

/// Ajuda de um modelo de ficha (uma semana inteira pronta).
Future<void> showModeloHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Modelo de ficha',
    subtitle: 'Uma semana inteira, pronta para aplicar em qualquer aluno.',
    tips: const [
      FxHelpTip(
        'Montar',
        'Toque numa sessão para preencher os exercícios. "Em montagem" quer dizer que ainda há sessão vazia.',
        icon: FxIcons.treino,
      ),
      FxHelpTip(
        'Aplicar em aluno',
        'Você escolhe o aluno e se mantém as cargas. A ficha dele é trocada por uma cópia do modelo, com 8 semanas de validade.',
        icon: FxIcons.grupo,
      ),
      FxHelpTip(
        'Cópia, não vínculo',
        'Mudar o modelo depois não altera as fichas que já foram aplicadas.',
        icon: FxIcons.artigo,
      ),
      FxHelpTip(
        'Volume da semana',
        'Séries por grupo muscular do modelo, como referência.',
        icon: FxIcons.grafico,
      ),
    ],
  );
}

/// Ajuda das fichas anteriores do aluno.
Future<void> showFichasAnterioresHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Fichas anteriores',
    subtitle: 'Cada vez que você troca a ficha inteira, a anterior fica guardada.',
    tips: const [
      FxHelpTip(
        'O que fica guardado',
        'Recomeçar, aplicar modelo, duplicar como base e copiar de outro aluno. Editar a semana ou renovar a validade não guardam nada.',
        icon: FxIcons.rota,
      ),
      FxHelpTip(
        'Usar como base',
        'Cria cópias das sessões que ainda existem, pergunta das cargas e começa 8 semanas novas. A ficha de agora também fica guardada.',
        icon: FxIcons.atualizar,
      ),
      FxHelpTip(
        'Sessão removida',
        'Se você excluiu um treino depois, ele aparece como removido e não entra na cópia.',
        icon: FxIcons.alerta,
      ),
      FxHelpTip(
        'Até 12 fichas',
        'O Focux guarda as 12 mais recentes de cada aluno.',
        icon: FxIcons.estrela,
      ),
    ],
  );
}
