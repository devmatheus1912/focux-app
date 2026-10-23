import '../../onboarding/data/setup_steps_catalog.dart';
import '../data/command_action_item.dart';

/// Card da primeira tela da Hoje do personal.
class HojePersonalCard {
  const HojePersonalCard({
    required this.titulo,
    required this.frase,
    required this.botao,
    required this.rota,
    this.acao,
  });

  final String titulo;
  final String frase;

  /// Nulo quando não há botão preenchido.
  final String? botao;
  final String? rota;

  /// Primeira ação da fila, quando o card é ela. O setup não tem item.
  final CommandActionItem? acao;

  bool get temBotao =>
      botao != null && botao!.isNotEmpty && rota != null && rota!.isNotEmpty;
}

/// Setup só ganha quando ainda não há aluno. A fila, quando existe, é a primeira ação.
HojePersonalCard hojePersonalCard({
  required List<CommandActionItem> acoes,
  required bool temAluno,
  SetupStepCatalogEntry? proximoPasso,
}) {
  if (!temAluno && proximoPasso != null) {
    return HojePersonalCard(
      titulo: proximoPasso.title,
      frase: proximoPasso.description,
      botao: proximoPasso.title,
      rota: proximoPasso.actionRoute,
    );
  }
  final fila = temAluno
      ? acoes
          .where((a) => a.actionKey != kCommandActionCriarOportunidade)
          .toList()
      : acoes;
  if (fila.isEmpty) {
    return const HojePersonalCard(
      titulo: 'Operação sob controle',
      frase: 'Nada para fazer agora.',
      botao: null,
      rota: null,
    );
  }
  final primeira = fila.first;
  final rota = primeira.route.trim();
  return HojePersonalCard(
    titulo: primeira.title,
    frase: primeira.subtitle,
    botao: rota.isEmpty ? null : primeira.title,
    rota: rota.isEmpty ? null : rota,
    acao: primeira,
  );
}
