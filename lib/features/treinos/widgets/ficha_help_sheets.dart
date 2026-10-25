import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';

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
        icon: 'calendar',
      ),
      FxHelpTip(
        'Vale por',
        'Escolha por quantas semanas a ficha vale. O Focux avisa 7 dias antes e no dia do vencimento, e você renova pelo próprio aviso.',
        icon: 'bell',
      ),
      FxHelpTip(
        'Modelos',
        'Aplique um modelo, salve esta ficha como modelo ou use em outro aluno. A ficha atual sai e entra uma cópia; editar uma não muda a outra.',
        icon: 'article',
      ),
      FxHelpTip(
        'Fichas anteriores',
        'Quando você troca a ficha inteira, a anterior fica guardada. Dá para consultar e usar como base de novo.',
        icon: 'route',
      ),
      FxHelpTip(
        'Volume da semana',
        'Mostra as séries de trabalho por grupo muscular, só como referência. Nada bloqueia a sua prescrição.',
        icon: 'trend',
      ),
      FxHelpTip(
        'Recomeçar',
        'Limpa a semana. Os treinos continuam salvos e a ficha de agora vai para as anteriores.',
        icon: 'refresh-cw',
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
        icon: 'dumbbell',
      ),
      FxHelpTip(
        'Aplicar em aluno',
        'Você escolhe o aluno e se mantém as cargas. A ficha dele é trocada por uma cópia do modelo, com 8 semanas de validade.',
        icon: 'users',
      ),
      FxHelpTip(
        'Cópia, não vínculo',
        'Mudar o modelo depois não altera as fichas que já foram aplicadas.',
        icon: 'article',
      ),
      FxHelpTip(
        'Volume da semana',
        'Séries por grupo muscular do modelo, como referência.',
        icon: 'trend',
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
        icon: 'route',
      ),
      FxHelpTip(
        'Usar como base',
        'Cria cópias das sessões que ainda existem, pergunta das cargas e começa 8 semanas novas. A ficha de agora também fica guardada.',
        icon: 'refresh-cw',
      ),
      FxHelpTip(
        'Sessão removida',
        'Se você excluiu um treino depois, ele aparece como removido e não entra na cópia.',
        icon: 'alert-triangle',
      ),
      FxHelpTip(
        'Até 12 fichas',
        'O Focux guarda as 12 mais recentes de cada aluno.',
        icon: 'star',
      ),
    ],
  );
}
