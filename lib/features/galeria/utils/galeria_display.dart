const galeriaMaxFotos = 9;

String galeriaCountLabel(int count) {
  if (count <= 0) return 'Nenhuma foto';
  if (count == 1) return '1 de $galeriaMaxFotos fotos';
  return '$count de $galeriaMaxFotos fotos';
}

String galeriaLimitLabel() => 'Limite de $galeriaMaxFotos fotos atingido.';
