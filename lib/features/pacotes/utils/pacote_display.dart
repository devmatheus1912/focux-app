String pacoteCountLabel(int count) {
  if (count <= 0) return 'Nenhum plano';
  if (count == 1) return '1 plano';
  return '$count planos';
}

enum PacoteChip { todos, destaque }

String pacoteChipLabel(PacoteChip chip) => switch (chip) {
  PacoteChip.todos => 'Todos',
  PacoteChip.destaque => 'Destaque',
};

bool pacoteMatches({
  required String titulo,
  required String? descricao,
  required bool destaque,
  required String query,
  required PacoteChip chip,
}) {
  if (chip == PacoteChip.destaque && !destaque) return false;
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (titulo.toLowerCase().contains(q)) return true;
  return (descricao ?? '').toLowerCase().contains(q);
}

const pacoteDuracaoMesesValues = [1, 3, 6, 12];
const pacoteTituloMax = 120;
const pacoteDescricaoMax = 4000;

String pacoteDuracaoLabel(int meses) {
  if (meses <= 1) return '1 mês';
  return '$meses meses';
}

String pacoteIncluiValue(bool on) => on ? 'Sim' : 'Não';

String pacoteCriarTileLabel() => 'Criar plano';

String pacoteCriarConfirmTitle() => 'Publicar este plano?';

String pacoteCriarConfirmMessage() =>
    'Quem abrir seu link passa a ver este plano na página de vendas.';

String pacoteCriarConfirmLabel() => 'Publicar';

String pacoteDesativarConfirmTitle() => 'Desativar plano?';

String pacoteDesativarConfirmMessage(String titulo) {
  final nome = titulo.trim();
  if (nome.isEmpty) {
    return 'Ele some da sua página na internet. Você pode criar outro depois.';
  }
  return '“$nome” some da sua página na internet. Você pode criar outro depois.';
}

String pacoteDesativarConfirmLabel() => 'Desativar';
