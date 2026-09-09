part of 'meus_treinos_screen.dart';

String meusTreinosCountLabel(int count) {
  if (count <= 0) return 'Nenhum treino';
  if (count == 1) return '1 treino';
  return '$count treinos';
}
