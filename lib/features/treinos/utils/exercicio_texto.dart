const _comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
const _semAcento = 'aaaaaeeeeiiiiooooouuuucn';

/// Minúsculas e sem acento: "Tríceps" vira "triceps". Usado em ordenação e
/// em comparações de texto livre.
String semAcento(String? texto) {
  final base = (texto ?? '').toLowerCase();
  final out = StringBuffer();
  for (final unidade in base.runes) {
    final c = String.fromCharCode(unidade);
    final i = _comAcento.indexOf(c);
    out.write(i >= 0 ? _semAcento[i] : c);
  }
  return out.toString();
}
