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

String depoimentoNotaLabel(int nota) {
  return switch (nota.clamp(1, 5)) {
    1 => '1 — Fraco',
    2 => '2 — Regular',
    3 => '3 — Bom',
    4 => '4 — Muito bom',
    _ => '5 — Excelente',
  };
}
