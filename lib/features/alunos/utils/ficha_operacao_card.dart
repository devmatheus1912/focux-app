import 'aluno360_operacao_logic.dart';

/// Card da primeira tela da aba Operação.
class FichaOperacaoCard {
  const FichaOperacaoCard({
    required this.titulo,
    required this.frase,
    required this.botao,
    required this.sticky,
  });

  final String titulo;
  final String frase;

  /// Nulo quando não há botão preenchido.
  final String? botao;
  final OperacaoStickyAction sticky;

  bool get temBotao => botao != null && botao!.isNotEmpty;
}

/// O card usa o sticky que já existe. Sem texto, só mensalidade, contato e tarefa têm botão.
FichaOperacaoCard fichaOperacaoCard({
  required OperacaoStickyAction sticky,
  required String? textoProximaAcao,
}) {
  final texto = textoProximaAcao?.trim() ?? '';
  if (texto.isNotEmpty) {
    return FichaOperacaoCard(
      titulo: sticky.label,
      frase: texto,
      botao: sticky.label,
      sticky: sticky,
    );
  }
  return _semTexto(sticky);
}

FichaOperacaoCard _semTexto(OperacaoStickyAction sticky) {
  if (sticky.destination == OperacaoStickyDestination.financeiro) {
    return FichaOperacaoCard(
      titulo: sticky.label,
      frase: 'A mensalidade está em aberto.',
      botao: sticky.label,
      sticky: sticky,
    );
  }
  if (sticky.destination == OperacaoStickyDestination.chat) {
    return FichaOperacaoCard(
      titulo: sticky.label,
      frase: 'O contato é o próximo passo.',
      botao: sticky.label,
      sticky: sticky,
    );
  }
  if (sticky.label == 'Ver tarefa') {
    return FichaOperacaoCard(
      titulo: sticky.label,
      frase: 'Tem uma tarefa aberta.',
      botao: sticky.label,
      sticky: sticky,
    );
  }
  return FichaOperacaoCard(
    titulo: sticky.label,
    frase: 'Nada urgente nesta ficha.',
    botao: null,
    sticky: sticky,
  );
}
