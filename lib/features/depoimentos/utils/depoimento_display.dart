enum DepoimentoChip { todos, pendentes, aprovados }

String depoimentoCountLabel(int count) {
  if (count <= 0) return 'Nenhum depoimento';
  if (count == 1) return '1 depoimento';
  return '$count depoimentos';
}

String depoimentoChipLabel(DepoimentoChip chip) => switch (chip) {
  DepoimentoChip.todos => 'Todos',
  DepoimentoChip.pendentes => 'Pendentes',
  DepoimentoChip.aprovados => 'Aprovados',
};

String depoimentoStatusLabel({required bool aprovado}) =>
    aprovado ? 'Aprovado' : 'Pendente';

/// Sem nota ainda (as estrelas começam vazias), pede o toque.
String depoimentoNotaLabel(int nota) {
  if (nota < 1) return 'Toque para dar uma nota';
  return switch (nota.clamp(1, 5)) {
    1 => '1 · Fraco',
    2 => '2 · Regular',
    3 => '3 · Bom',
    4 => '4 · Muito bom',
    _ => '5 · Excelente',
  };
}

/// O que falta para enviar; nulo quando já dá.
String? depoimentoFalta({required int nota, required String texto}) {
  if (nota < 1) return 'Escolha uma nota';
  final n = texto.trim().length;
  if (n < 10) return 'Escreva pelo menos 10 letras (faltam ${10 - n})';
  return null;
}
