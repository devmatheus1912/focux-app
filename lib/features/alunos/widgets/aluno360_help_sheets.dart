import 'package:flutter/material.dart';

import '../../../core/widgets/fx_help.dart';
import '../../../core/theme/fx_icons.dart';

/// Ajuda da aba Resumo do perfil 360.
Future<void> showAluno360ResumoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Resumo do aluno',
    subtitle: 'O que fazer com este aluno agora, em uma tela só.',
    tips: const [
      FxHelpTip(
        'Agora',
        'A ação mais importante, com o motivo e um botão (Chamar, Cobrar, Abrir). Sem nada urgente, a tela diz isso.',
        icon: FxIcons.alvo,
      ),
      FxHelpTip(
        'Números',
        'Aderência dos últimos 30 dias, dias sem treino e check-ins da semana. Tocar abre o engajamento. Quem ainda não treinou aparece como "Sem treinos ainda", não como 0%.',
        icon: FxIcons.grafico,
      ),
      FxHelpTip(
        'Ficha de treino',
        'A semana do aluno, a validade e o botão Abrir ficha. A validade avisa; nunca bloqueia o aluno.',
        icon: FxIcons.calendario,
      ),
      FxHelpTip(
        'Próximo contato',
        'Agende o retorno, marque contato feito ou adie. A data fica salva para o aluno e para você.',
        icon: FxIcons.notificacao,
      ),
      FxHelpTip(
        'Menu ⋮',
        'Editar cadastro, criar tarefa, pausar ou bloquear o acesso e, por último, excluir o aluno (pede confirmação). O Chat fica no topo.',
        icon: FxIcons.raio,
      ),
    ],
  );
}

/// Ajuda da aba Evolução do perfil 360.
Future<void> showAluno360EvolucaoHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Evolução do aluno',
    subtitle: 'Se ele está progredindo e o que mudou desde a última vez.',
    tips: const [
      FxHelpTip(
        'Evolução inteligente',
        'Volume e tendência a partir dos check-ins. Com a tela vazia, peça um check-in.',
        icon: FxIcons.grafico,
      ),
      FxHelpTip(
        'Linha do tempo',
        'Alertas, check-ins, chat e medidas recentes, do mais novo para o mais antigo. O que o aluno só visualizou no app não aparece. Toque para ver o detalhe.',
        icon: FxIcons.artigo,
      ),
      FxHelpTip(
        'Peso e tendência',
        'O peso vem da avaliação mais recente; sem avaliação, do cadastro (e diz isso). O gráfico precisa de duas medidas. Valor fora do normal aparece como "Confirme este valor".',
        icon: FxIcons.treino,
      ),
      FxHelpTip(
        'Ajustar treino',
        'Abre os treinos do aluno para mudar a prescrição a partir do que você viu aqui.',
        icon: FxIcons.alvo,
      ),
    ],
  );
}

/// Ajuda da aba Ferramentas do perfil 360.
Future<void> showAluno360FerramentasHelpSheet(BuildContext context) {
  return showFxHelpSheet(
    context,
    title: 'Ferramentas do aluno',
    subtitle: 'Tudo o que você pode fazer por este aluno, por tarefa.',
    tips: const [
      FxHelpTip(
        'Grupos',
        'Treino, Acompanhamento, Relação e Dinheiro. Todos os módulos aparecem; o grupo com algo urgente sobe para o topo.',
        icon: FxIcons.artigo,
      ),
      FxHelpTip(
        'Selos',
        'Cada linha mostra o estado: Pendente, Revisar, Em atraso, Confirme este valor. O selo do plano (Pro, Enterprise) abre o upgrade.',
        icon: FxIcons.estrela,
      ),
      FxHelpTip(
        'Dados do aluno',
        'Contato, objetivo, nascimento e altura. Se faltar algum, o grupo abre a aba; tocar em qualquer linha leva ao cadastro.',
        icon: FxIcons.grupo,
      ),
      FxHelpTip(
        'Composição corporal',
        'Gordura e massa magra da última avaliação. Número fora do normal pede confirmação em vez de aparecer como OK.',
        icon: FxIcons.grafico,
      ),
    ],
  );
}
