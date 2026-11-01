
/// "(meu)": nome da cópia que o personal cria a partir de um exercício Focux.
String nomeDaCopia(String original) {
  final base = original.trim();
  return base.endsWith('(meu)') ? base : '$base (meu)';
}
