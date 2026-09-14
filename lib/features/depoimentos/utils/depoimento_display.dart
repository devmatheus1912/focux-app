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

bool depoimentoMatches({
  required String nomeAluno,
  required String texto,
  required bool aprovado,
  required String query,
  required DepoimentoChip chip,
}) {
  final matchesChip = switch (chip) {
    DepoimentoChip.todos => true,
    DepoimentoChip.pendentes => !aprovado,
    DepoimentoChip.aprovados => aprovado,
  };
  if (!matchesChip) return false;
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return nomeAluno.toLowerCase().contains(q) ||
      texto.toLowerCase().contains(q);
}

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
